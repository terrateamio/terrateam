variable "iam_instance_profile" {}

/**
 * インスタンス作成
 * https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
 */
resource "aws_instance" "web_instance" {
  count                       = 1
  ami                         = "ami-02c3627b04781eada"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [resource.aws_security_group.sg_web_instance.id]
  subnet_id                   = split(",", module.before.private_subnet_ids)[count.index % length(split(",", module.before.private_subnet_ids))]
  associate_public_ip_address = false
  iam_instance_profile        = var.iam_instance_profile

  tags = {
    Name = format("${var.user_name}-web-instance%04d", count.index + 1)
  }

  volume_tags = {
    Name = "${format("${var.user_name}-web-instance%04d", count.index + 1)}-ebs"
  }
}

resource "aws_instance" "web_instance2" {
  ami                         = [作成したカスタムAMI]
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [resource.aws_security_group.sg_web_instance.id]
  subnet_id                   = split(",", module.before.private_subnet_ids)[1]
  associate_public_ip_address = false
  iam_instance_profile        = var.iam_instance_profile

  tags = {
    Name = "${var.user_name}-web-instance2-0001"
  }

  volume_tags = {
    Name = "${var.user_name}-web-instance2-0001-ebs"
  }
}
