resource "humanitec_resource_definition" "azure_blob_account" {
  driver_type = "humanitec/terraform"
  id          = "azure-blob-account-basic"
  name        = "azure-blob-account-basic"
  type        = "azure-blob-account"

  driver_inputs = {
    secrets_string = jsonencode({
      # Secret info of the cluster where the Terraform Runner should run.
      # This references a k8s-cluster resource that will be matched by class `runner`.
      runner = jsonencode({
        credentials = "$${resources['k8s-cluster.runner'].outputs.credentials}"
      })

      source = {
        ssh_key = var.ssh_key
      }
    })

    values_string = jsonencode({
      append_logs_to_error = true

      # This instructs the driver that the Runner must be run in an external cluster.
      runner_mode = "custom-kubernetes"
      # Non-secret info of the cluster where the Terraform Runner should run.
      # This references a k8s-cluster resource that will be matched by class `runner`.
      runner = {
        cluster_type = "aks"
        cluster = {
          region                   = "$${resources['k8s-cluster.runner'].outputs.region}"
          name                     = "$${resources['k8s-cluster.runner'].outputs.name}"
          loadbalancer             = "$${resources['k8s-cluster.runner'].outputs.loadbalancer}"
          loadbalancer_hosted_zone = "$${resources['k8s-cluster.runner'].outputs.loadbalancer_hosted_zone}"
        }
        # Service Account created following: https://developer.humanitec.com/integration-and-extensions/drivers/generic-drivers/terraform/#runner-object
        # In this example, the Service Account needs to be annotated to specify the Microsoft Entra application client ID to be used with the pod: https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview?tabs=dotnet#service-account-labels-and-annotations
        service_account = "humanitec-tf-runner-sa"
        namespace       = "humanitec-tf-runner"
        # This instructs the driver that the Runner pod must run with a workload identity.
        runner_pod_template = <<EOT
metadata:
  labels:
    azure.workload.identity/use: "true"
EOT
      }

      # Connection information to the Git repo containing the Terraform code.
      # It will provide a backend configuration initialized via Environment Variables.
      source = {
        path = "modules/azure-blob-account/basic"
        rev  = var.resource_packs_azure_rev
        url  = var.resource_packs_azure_url
      }
      variables = {
        res_id = "$${context.res.id}"
        app_id = "$${context.app.id}"
        env_id = "$${context.env.id}"

        subscription_id          = var.subscription_id
        resource_group_name      = var.resource_group_name
        name                     = var.name
        prefix                   = var.prefix
        account_tier             = var.account_tier
        account_replication_type = var.account_replication_type
      }
    })
  }
}
