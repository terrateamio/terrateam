locals {
  # annoyingly it doesn't seem to work if I replace this with keys(module.vpc.subnets)
  # actually it does once setup the first time, but not when bootstrapping
  # Will work with HCL2 in version 12 of terraform
  # TODO https://github.com/hashicorp/terraform/issues/16712
  subnet_types = ["instance", "public", "private"]
}

resource "aws_ssm_parameter" "instance_subnets" {
  name        = "/${var.app_name}/${terraform.workspace}/vpc/subnets/instance"
  description = "The ${var.app_name}'s vpc's instance subnets"
  type        = "StringList"

  value = join(
  ",",
  slice(
  concat(aws_subnet.private.*.id, aws_subnet.public.*.id),
  var.create_private ? 0 : length(aws_subnet.private.*.id),
  var.create_private ? length(aws_subnet.private.*.id) : length(aws_subnet.private.*.id) + length(aws_subnet.public.*.id),
  ),
  )

  overwrite = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_ssm_parameter" "public_subnets" {
  name        = "/${var.app_name}/${terraform.workspace}/vpc/subnets/public"
  description = "The ${var.app_name}'s vpc's public subnets"
  type        = "StringList"
  value       = join(",", aws_subnet.public.*.id)
  overwrite   = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_ssm_parameter" "private_subnets" {
  count       = var.create_private ? 1 : 0
  name        = "/${var.app_name}/${terraform.workspace}/vpc/subnets/private"
  description = "The ${var.app_name}'s vpc's private subnets"
  type        = "StringList"
  value       = join(",", aws_subnet.private.*.id)
  overwrite   = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_ssm_parameter" "using_private" {
  name        = "/${var.app_name}/${terraform.workspace}/vpc/using_private_subnets"
  description = "Whether the VPC has been configured to use private subnets"
  type        = "String"
  value       = var.create_private
  overwrite   = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_ssm_parameter" "num_azs" {
  name        = "/${var.app_name}/${terraform.workspace}/vpc/num_azs"
  description = "How many AZs VPC has been configured to use"
  type        = "String"
  value       = local.az_count
  overwrite   = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_ssm_parameter" "cidr_block" {
  name        = "/${var.app_name}/${terraform.workspace}/vpc/cidr_block"
  description = "The ${var.app_name}'s vpc's cidr block"
  type        = "String"
  value       = aws_vpc.vpc.cidr_block
  overwrite   = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_ssm_parameter" "id" {
  name        = "/${var.app_name}/${terraform.workspace}/vpc/id"
  description = "The ${var.app_name}'s vpc's id"
  type        = "String"
  value       = aws_vpc.vpc.id
  overwrite   = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}
