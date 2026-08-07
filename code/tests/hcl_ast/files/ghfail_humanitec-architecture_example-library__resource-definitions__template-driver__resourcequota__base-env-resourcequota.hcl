resource "humanitec_resource_definition" "base-env" {
  driver_type = "humanitec/template"
  id          = "base-env"
  name        = "base-env"
  type        = "base-env"
  driver_inputs = {
    values_string = jsonencode({
      "templates" = {
        "manifests" = "quota.yaml:\n  location: namespace\n  data:\n    apiVersion: v1\n    kind: ResourceQuota\n    metadata:\n      name: compute-resources\n    spec:\n      hard:\n        limits.cpu: $${resources['config#quota'].outputs.limits-cpu}\n        limits.memory: $${resources['config#quota'].outputs.limits-memory}"
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "base-env_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.base-env.id

}
