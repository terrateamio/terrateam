# AWS Provider Info
provider "aws" {
  profile = var.aws-profile
  region = var.aws-region
}


# VPC + Network Configurations
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/26"
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/28"
  availability_zone = var.aws-availability-zone
}

resource "aws_internet_gateway" "iw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.iw.id
  }
}

resource "aws_route_table_association" "public_route_assoc" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}
resource "aws_security_group" "http_ingress" {
  name = "allow_http_ingress"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

}

resource "aws_security_group" "https_ingress" {
  name = "allow_https_ingress"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

}


resource "aws_instance" "ec2_server" {
  ami = var.ami_image
  availability_zone = var.aws-availability-zone
  instance_type = var.instance_type
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = "true"
  key_name = "admin-key"
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.http_ingress.id,
    aws_security_group.https_ingress.id,
  ]
}


resource "aws_eip" "meet_ip" {
  vpc = true

  instance                  = aws_instance.ec2_server.id
  depends_on                = [aws_internet_gateway.iw]
}


resource "aws_route53_record" "jitsi" {
  zone_id = var.zone_id
  name    = var.notebooks_domain_name
  type    = "A"
  ttl     = "300"
  records = [aws_eip.meet_ip.public_ip]
}

# EBS Storage Configurations

#resource "aws_ebs_volume" "eeg_data" {
#  availability_zone = "us-west-2a"
#  size              = 100
#
#  tags = {
#    Name = "neureka-challenge"
#  }
#}

#resource "aws_volume_attachment" "eeg_data_att" {
#  device_name = "/dev/sdh"
#  volume_id   = "vol-05bf5deb0c2acfbde"
#  instance_id = aws_instance.ec2_server.id
#}