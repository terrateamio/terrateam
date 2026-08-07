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
      "source" = {
        "ref" = "refs/heads/main"
        "url" = "git@github.com:my-org/my-repo.git"
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
      }
    })
    secret_refs = jsonencode({
      "cluster" = {
        "agent_url" = {
          "value" = "$${resources['config.runner'].outputs.agent_url}"
        }
      }
      "source" = {
        "ssh_key" = {
          "store" = "my-secret-store"
          "ref"   = "my-path-to-git-ssh-key"
        }
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "aws-s3_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.aws-s3.id
  env_type               = "development"
}
