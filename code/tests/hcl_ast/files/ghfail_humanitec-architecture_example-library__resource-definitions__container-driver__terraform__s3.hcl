resource "humanitec_resource_definition" "aws-s3" {
  driver_type    = "humanitec/container"
  id             = "aws-s3"
  name           = "aws-s3"
  type           = "s3"
  driver_account = "aws-ref-arch"
  driver_inputs = {
    values_string = jsonencode({
      "job" = {
        "image" = "hashicorp/terraform:1.5.7"
        "command" = [
          "/bin/sh",
          "/home/runneruser/workspace/run.sh"
        ]
        "shared_directory" = "/home/runneruser/workspace"
        "namespace"        = "humanitec-runner"
        "service_account"  = "humanitec-runner"
      }
      "cluster" = {
        "account" = "my-org/my-aws-cloud-account"
        "cluster" = "$${resources[\"k8s-cluster.default#k8s-cluster\"].values}"
      }
      "credentials_config" = {
        "environment" = {
          "AWS_ACCESS_KEY_ID"     = "AccessKeyId"
          "AWS_SECRET_ACCESS_KEY" = "SecretAccessKey"
          "AWS_SESSION_TOKEN"     = "SessionToken"
        }
      }
      "files" = {
        "run.sh"                = <<END_OF_TEXT
#!/bin/sh

# NOTE: This script is written to be POSIX shell compatible.

# run_cmd runs the command provided in its input args.
# If the command fails, STDERR from the command is written to ERROR_FILE and
# also to STDERR and the script exists with exit code 1.
run_cmd ()
{
    if ! "$@" 2> "$\{ERROR_FILE}"
    then
        echo
        echo "FAILED: $@"
        cat "$\{ERROR_FILE}" 1>&2
        exit 1
    fi
}

if ! [ -d "$\{SCRIPTS_DIRECTORY}" ]
then
    echo "SCRIPTS_DIRECTORY does not exist: \"$\{SCRIPTS_DIRECTORY}"\" > "$\{ERROR_FILE}"
    cat "$\{ERROR_FILE}" 1>&2
    exit 1
fi

run_cmd cd "$\{SCRIPTS_DIRECTORY}"

if [ "$\{ACTION}" = "create" ]
then
    run_cmd terraform init -no-color

    run_cmd terraform apply -auto-approve -input=false -no-color
    
    # Terraform can export its outputs with the following schema:
    #   {
    #     "output-name": {
    #       "sensitive": bool: true of output is marked sensitive
    #       "type": string: the Terraform type of the output
    #       "value": any: the JSON representation of the output value
    #     },
    #     ...
    #   }
    # 
    # The container driver, expects a simple map of output-name: value
    #
    # The hashicorp/terraform does not provide any special tooling to
    # manipulate JSON. However, terraform accepts inputs and JSON so can use
    # an additional run of the terraform CLI to manipulate the JSON.

    # Create a new directory do convert the JSON outputs.
    mkdir output_parse_container

    # Generate a tfvars file in JSON format without any JSON tooling with a
    # single variable of "in".
    echo '{"in":' > output_parse_container/terraform.tfvars.json
    run_cmd terraform output -json >> output_parse_container/terraform.tfvars.json
    echo '}' >> output_parse_container/terraform.tfvars.json

    # Move to a different directory and therefore a different terraform context
    # This means if we run terraform apply, it will be independent from the main
    # request above.
    run_cmd cd output_parse_container

    # Inject the Terraform code that converts the input into 2 separate maps
    # depending on whether the value is marked as sensitive or not.
    echo 'variable "in" { type = map }
output "values" { value = {for k, v in var.in: k => v.value if !v.sensitive} }
output "secrets" { value = {for k, v in var.in: k => v.value if v.sensitive} }' > parse.tf

    echo
    echo "Converting outputs using terraform apply"

    # This terraform apply is just operating on the terraform.tfvars.json
    # created above. It is running in a new terraform context and so will
    # not influence the infrastructure deployed above
    # Note: no need to run terraform init as no providers are required
    run_cmd terraform apply -auto-approve -input=false -no-color > /dev/null

    run_cmd terraform output -json values > "$\{OUTPUTS_FILE}"

    run_cmd terraform output -json secrets > "$\{SECRET_OUTPUTS_FILE}"

    echo "Done."

elif [ "$\{ACTION}" = "destroy" ]
then
    run_cmd terraform init -no-color

    run_cmd terraform destroy -auto-approve -input=false -no-color

else
  echo "unrecognized ACTION: \"$\{ACTION}"\" > "$\{ERROR_FILE}"
  cat "$\{ERROR_FILE}" 1>&2
  exit 1
fi
END_OF_TEXT
        "terraform.tfvars.json" = "{\"REGION\": \"eu-west-3\", \"BUCKET\": \"$${context.app.id}-$${context.env.id}\"}\n"
        "backend.tf"            = <<END_OF_TEXT
terraform {
  backend "s3" {
    bucket = "my-s3-to-store-tf-state"
    key = "$${context.res.guresid}/state/terraform.tfstate"
    region = "eu-central-1"
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
          "value" = "$${resources['agent.default#runner'].outputs.url}"
        }
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "aws-s3_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.aws-s3.id
  env_type               = "development"
  app_id                 = "container-test"
}
