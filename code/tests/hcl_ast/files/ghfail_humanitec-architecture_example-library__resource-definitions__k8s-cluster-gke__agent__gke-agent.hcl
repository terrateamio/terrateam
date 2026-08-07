resource "humanitec_resource_definition" "gke-agent" {
  driver_type    = "humanitec/k8s-cluster-gke"
  id             = "gke-agent"
  name           = "gke-agent"
  type           = "k8s-cluster"
  driver_account = "gcp-temporary-creds"
  driver_inputs = {
    values_string = jsonencode({
      "loadbalancer" = "35.10.10.10"
      "name"         = "demo-123"
      "zone"         = "europe-west2-a"
      "project_id"   = "my-gcp-project"
    })
    secrets_string = jsonencode({
      "agent_url" = "$${resources['agent#agent'].outputs.url}"
    })
  }
}

