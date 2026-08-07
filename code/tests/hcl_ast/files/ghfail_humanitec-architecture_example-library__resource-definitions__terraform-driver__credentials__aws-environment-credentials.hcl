resource "humanitec_resource_definition" "aws-environment-credentials" {
  driver_type    = "humanitec/terraform"
  id             = "aws-environment-credentials"
  name           = "aws-environment-credentials"
  type           = "s3"
  driver_account = "$${resources['config.default#aws-account'].account}"
  driver_inputs = {
    values_string = jsonencode({
      "credentials_config" = {
        "environment" = {
          "AWS_ACCESS_KEY_ID"     = "AccessKeyId"
          "AWS_SECRET_ACCESS_KEY" = "SecretAccessKey"
          "AWS_SESSION_TOKEN"     = "SessionToken"
        }
      }
      "script" = <<END_OF_TEXT

variable "region" {}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

output "bucket" {
  value = aws_s3_bucket.bucket.bucket
}

output "region" {
  value = var.region
}

resource "aws_s3_bucket" "bucket" {
  bucket = "$\{replace("$${context.res.id}", "/^.*\\./", "")}-standard-$${context.env.id}-$${context.app.id}-$${context.org.id}"
  tags = {
    Humanitec = true
  }
}
END_OF_TEXT
      "variables" = {
        "region" = "$${resources['config.default#aws-account'].outputs.region}"
      }
    })
  }
}


