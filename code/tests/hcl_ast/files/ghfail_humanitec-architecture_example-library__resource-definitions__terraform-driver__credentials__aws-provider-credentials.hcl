resource "humanitec_resource_definition" "aws-provider-credentials" {
  driver_type    = "humanitec/terraform"
  id             = "aws-provider-credentials"
  name           = "aws-provider-credentials"
  type           = "s3"
  driver_account = "$${resources['config.default#aws-account'].account}"
  driver_inputs = {
    values_string = jsonencode({
      "credentials_config" = {
        "variables" = {
          "access_key_id"     = "AccessKeyId"
          "secret_access_key" = "SecretAccessKey"
          "session_token"     = "SessionToken"
        }
      }
      "script" = <<END_OF_TEXT

variable "access_key_id" {
  sensitive = true
}
variable "secret_access_key" {
  sensitive = true
}
variable "session_token" {
  sensitive = true
}
variable "region" {}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key_id
  secret_key = var.secret_access_key
  token      = var.session_token
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


