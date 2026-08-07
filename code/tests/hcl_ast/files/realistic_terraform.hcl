terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "bucket_names" {
  type    = list(string)
  default = ["logs", "data"]
}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  bucket_count = length(var.bucket_names)
}

resource "aws_s3_bucket" "main" {
  for_each = toset(var.bucket_names)

  bucket = "${var.environment}-${each.key}-bucket"

  tags = merge(local.common_tags, {
    Purpose = each.key
  })
}

resource "aws_instance" "web" {
  count = var.environment == "prod" ? 3 : 1

  ami           = "ami-12345"
  instance_type = "t2.micro"

  tags = local.common_tags
}

output "bucket_ids" {
  value = [for k, v in aws_s3_bucket.main : v.id]
}

output "instance_count" {
  value = local.bucket_count > 0 ? length(aws_instance.web) : 0
}
