resource "humanitec_resource_definition" "gke-temporary-credentials-runtime" {
  driver_type    = "humanitec/k8s-cluster-gke"
  id             = "gke-temporary-credentials-runtime"
  name           = "gke-temporary-credentials-runtime"
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

resource "humanitec_resource_definition_criteria" "gke-temporary-credentials-runtime_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.gke-temporary-credentials-runtime.id
  res_id                 = "k8s-cluster-runtime"
}
