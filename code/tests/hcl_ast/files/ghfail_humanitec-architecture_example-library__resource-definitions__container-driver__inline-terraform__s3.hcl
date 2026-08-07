resource "humanitec_resource_definition" "aws-s3" {
  driver_type    = "humanitec/container"
  id             = "aws-s3"
  name           = "aws-s3"
  type           = "s3"
  driver_account = "my-aws-cloud-account"
  driver_inputs = {
    values_string = jsonencode({
      "job"     = "$${resources['config.runner'].outputs.job}"
      "cluster" = "$${resources['config.runner'].outputs.cluster}"
      "credentials_config" = {
        "environment" = {
          "AWS_ACCESS_KEY_ID"     = "AccessKeyId"
          "AWS_SECRET_ACCESS_KEY" = "SecretAccessKey"
        }
      }
      "files" = {
        "terraform.tfvars.json" = "{\"REGION\": \"eu-west-3\", \"BUCKET\": \"$${context.app.id}-$${context.env.id}\"}\n"
        "backend.tf"            = <<END_OF_TEXT
terraform {
  backend "s3" {
    bucket = "my-s3-to-store-tf-state"
    key = "$${context.res.guresid}/state/terraform.tfstate"
    region = "eu-west-3"
  }
}
END_OF_TEXT
        "providers.tf"          = <<END_OF_TEXT
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.72.0"
    }
  }
}
END_OF_TEXT
        "vars.tf"               = <<END_OF_TEXT
variable "REGION" {
    type = string
}

variable "BUCKET" {
    type = string
}
END_OF_TEXT
        "main.tf"               = <<END_OF_TEXT
provider "aws" {
  region     = var.REGION
  default_tags {
    tags = {
      CreatedBy = "Humanitec"
    }
  }
}

resource "random_string" "bucket_suffix" {
  length           = 5
  special          = false
  upper            = false
}

module "aws_s3" {
  source = "terraform-aws-modules/s3-bucket/aws"
  bucket = format("%s-%s", var.BUCKET, random_string.bucket_suffix.result)
  acl    = "private"
  force_destroy = true
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
}

output "region" {
  value = module.aws_s3.s3_bucket_region
}

output "bucket" {
  value = module.aws_s3.s3_bucket_id
}
END_OF_TEXT
      }
    })
    secret_refs = jsonencode({
      "cluster" = {
        "agent_url" = {
          "value" = "$${resources['config.runner'].outputs.agent_url}"
        }
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "aws-s3_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.aws-s3.id
  env_type               = "development"
}
