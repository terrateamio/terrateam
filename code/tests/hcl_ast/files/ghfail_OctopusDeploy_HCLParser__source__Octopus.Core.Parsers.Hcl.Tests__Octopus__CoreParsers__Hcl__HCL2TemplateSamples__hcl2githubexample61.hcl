#################################################
# VARIABLES
#################################################

variable "access_key" { type = string }

variable "secret_key" { type = string }

variable "aws_region" { type = string }

variable "vpc-name" { type = string }

variable "security-group-name" { type = string }

variable "instance_ami" { type = string }

variable "ec2-instance-type" { type = string }

variable "key-name" { type = string }