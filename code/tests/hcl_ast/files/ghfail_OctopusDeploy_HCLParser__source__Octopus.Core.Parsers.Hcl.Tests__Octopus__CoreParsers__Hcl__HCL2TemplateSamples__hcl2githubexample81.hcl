resource "aws_instance""Mouse"{
  count = var.instance_count
  placement_group = "${var.placement_group}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.allow_ssh_and_http.name}"]
  tags = {
    Name = "${var.instance_name}-${count.index+1}"
  }
}
resource "aws_security_group" "allow_ssh_and_http" {
  name = "my_ssh_http"
  vpc_id      = var.vpc_id
  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    protocol = "tcp"
    from_port = 80
    to_port  = 80
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow ssh and http only"
  }
}