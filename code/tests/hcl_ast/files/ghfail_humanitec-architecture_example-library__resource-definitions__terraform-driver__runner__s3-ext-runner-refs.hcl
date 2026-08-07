resource "humanitec_resource_definition" "aws_terraform_external_runner_resource_s3_bucket" {
  id          = "aws-terrafom-ext-runner-s3-bucket"
  name        = "aws-terrafom-ext-runner-s3-bucket"
  type        = "s3"
  driver_type = "humanitec/terraform"
  # The driver_account references a Cloud Account configured in the Platform Orchestrator.
  # Replace with the name of your AWS Cloud Account.
  # The account is used to provide credentials to the Terraform script via environment variables to access the TF state.
  driver_account = "my-aws-account"

  driver_inputs = {
    secrets_string = jsonencode({
      # Secret info of the cluster where the Terraform Runner should run.
      # This references a k8s-cluster resource that will be matched by class `runner`.
      runner = {
        credentials = "$${resources['k8s-cluster.runner'].outputs.credentials}"
      }

      source = {
        ssh_key = var.ssh_key
      }
      }
    )

    values_string = jsonencode({
      # This instructs the driver that the Runner must run in an external cluster.
      runner_mode = "custom-kubernetes"
      # Non-secret info of the cluster where the Terraform Runner should run.
      # This references a k8s-cluster resource that will be matched by class `runner`.
      runner = {
        cluster_type = "eks"
        cluster = {
          region                   = "$${resources['k8s-cluster.runner'].outputs.region}"
          name                     = "$${resources['k8s-cluster.runner'].outputs.name}"
          loadbalancer             = "$${resources['k8s-cluster.runner'].outputs.loadbalancer}"
          loadbalancer_hosted_zone = "$${resources['k8s-cluster.runner'].outputs.loadbalancer_hosted_zone}"
        }
        # Service Account created following: https://developer.humanitec.com/integration-and-extensions/drivers/generic-drivers/terraform/#runner-object
        service_account = "humanitec-tf-runner-sa"
        namespace       = "humanitec-tf-runner"
      }

      # Configure the way we provide account credentials to the Terraform scripts in the referenced repository.
      # These credentials are related to the `driver_account` configured above.
      credentials_config = {

        # Terraform script Variables. 
        variables = {
          ACCESS_KEY_ID     = "AccessKeyId"
          SECRET_ACCESS_KEY = "SecretAccessKey"
        }

        # Environment Variables.
        environment = {
          AWS_ACCESS_KEY_ID     = "AccessKeyId"
          AWS_SECRET_ACCESS_KEY = "SecretAccessKey"
        }
      }

      # Connection information to the Git repo containing the Terraform code.
      # It will provide a backend configuration initialized via Environment Variables.
      source = {
        path = "s3/terraform/bucket/"
        rev  = "refs/heads/main"
        url  = "my-domain.com:my-org/my-repo.git"
      }


      variables = {
        # Provide a separate bucket per Application and Environment
        bucket = "my-company-my-app-$${context.app.id}-$${context.env.id}"
        region = var.region
      }
    })
  }
}
