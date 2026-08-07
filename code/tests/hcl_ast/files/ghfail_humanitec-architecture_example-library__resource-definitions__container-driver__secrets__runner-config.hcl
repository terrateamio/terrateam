resource "humanitec_resource_definition" "container-driver-secrets-example-config" {
  driver_type = "humanitec/echo"
  id          = "container-driver-secrets-example-config"
  name        = "container-driver-secrets-example-config"
  type        = "config"
  driver_inputs = {
    values_string = jsonencode({
      "job" = {
        "image" = "ghcr.io/my-registry/container-driver-runner:1.0.1"
        "command" = [
          "/opt/container"
        ]
        "shared_directory" = "/home/runneruser/workspace"
      }
      "cluster" = {
        "account" = "my-org/my-aws-cloud-account"
        "cluster" = {
          "cluster_type" = "eks"
          "loadbalancer" = "10.10.10.10"
          "name"         = "my-demo-cluster"
          "region"       = "eu-west-3"
        }
      }
    })
    secret_refs = jsonencode({
      "agent_url" = {
        "value" = "$${resources['agent.default#agent'].outputs.url}"
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "container-driver-secrets-example-config_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.container-driver-secrets-example-config.id
  app_id                 = "container-driver-secrets-example"
  class                  = "runner"
}
