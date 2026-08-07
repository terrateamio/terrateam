resource "humanitec_resource_definition" "config-container-driver" {
  driver_type = "humanitec/echo"
  id          = "config-container-driver"
  name        = "config-container-driver"
  type        = "config"
  driver_inputs = {
    values_string = jsonencode({
      "job" = {
        "image" = "ghcr.io/my-registry/container-driver-runner:1.0.1"
        "command" = [
          "/opt/container"
        ]
        "shared_directory" = "/home/runneruser/workspace"
        "namespace"        = "humanitec-runner"
        "service_account"  = "humanitec-runner"
        "pod_template"     = <<END_OF_TEXT
spec:
  imagePullSecrets:
    - name: ghcr-private-registry
END_OF_TEXT
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

resource "humanitec_resource_definition_criteria" "config-container-driver_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.config-container-driver.id
  env_type               = "development"
  class                  = "runner"
}
