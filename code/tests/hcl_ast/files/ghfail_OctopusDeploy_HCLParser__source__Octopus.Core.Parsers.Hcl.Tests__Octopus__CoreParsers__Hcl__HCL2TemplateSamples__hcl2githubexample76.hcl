provider "aws" {
  region = var.region
}

# VPC: Virtual Private Cloud, is an SDN (Software-Defined Network) abstraction
# that sections off a piece of the "cloud" and isolates it from the WWW.
resource "aws_vpc" "main" {
  cidr_block = "${var.cidr_prefix}.0.0/16"
  # /16 means the first 16 bits are fixed and the rest is
  # whatever.  This allows for 256^2 = 65,536 addresses.
}

# VPC is sectioned into logical sub-units called subnets.  Here, one public and
# one private subnet are created. Public subnet will be accessible from the WWW,
# private one will not.
resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${var.region}${var.az}"
  # public assets will have internal IPs beginning with:
  # 222.33.1, there are 255 such addresses
  cidr_block        = "${var.cidr_prefix}.1.0/24"
}
resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${var.region}${var.az}"
  # private assets will have internal IPs beginning with:
  # 222.33.2, there are 255 such addresses
  cidr_block        = "${var.cidr_prefix}.2.0/24"
}

# Internet Gateway provides access to and from the WWW.
resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

# Route WWW-bound traffic from the public subnet through the Internet Gateway.
resource "aws_route_table" "public_to_www" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
}
resource "aws_route_table_association" "public_association" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public_to_www.id}"
}

# Route WWW-bound traffic from the private subnet through the Bastion/NAT host.
resource "aws_route_table" "private_to_nat" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.bastion.id}"
  }
}
resource "aws_route_table_association" "private_association" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private_to_nat.id}"
}

# Bastion/NAT EC2 box is wrapped in a security group which only allows SSH
# traffic into the instance from WWW, any traffic from the VPC, and any traffic
# out of it.
resource "aws_security_group" "bastion" {
  name        = "Bastion"
  description = "Allow inbound SSH traffic and NAT stuff"
  vpc_id      = "${aws_vpc.main.id}"

  # SSH traffic in
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # any traffic out
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  # any traffic from within
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${var.cidr_prefix}.0.0/16"]
  }
}

# Bastion/NAT host
resource "aws_instance" "bastion" {
  ami                         = var.bastion_nat_ami
  instance_type               = var.bastion_nat_size
  key_name                    = var.ec2_key
  subnet_id                   = "${aws_subnet.public.id}"
  vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
  associate_public_ip_address = true
  source_dest_check           = false
  tags = {
    Name = "Bastion Host and NAT"
  }
}

# Worker Bee EC2 box is wrapped in a security group that permits any traffic
# within the subnet and SSH traffic from the public subnet.
resource "aws_security_group" "worker_bee" {
  name        = "Worker Bee"
  description = "Allow inbound SSH traffic"
  vpc_id      = "${aws_vpc.main.id}"

  # SSH traffic from the public subnet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_prefix}.1.0/24"]
  }

  # any traffic from its own subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_prefix}.2.0/24"]
  }

  # any traffic out
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Worker Bee EC2
resource "aws_instance" "worker" {
  # Amazon Linux 2 AMI (HVM), SSD Volume
  ami                    = var.worker_bee_ami
  instance_type          = var.worker_bee_size
  key_name               = var.ec2_key
  subnet_id              = "${aws_subnet.private.id}"
  vpc_security_group_ids = ["${aws_security_group.worker_bee.id}"]
  tags = {
    Name = "Worker Bee"
  }
}