resource "humanitec_resource_definition" "example-k8s-service-account" {
  driver_type = "humanitec/template"
  id          = "example-k8s-service-account"
  name        = "example-k8s-service-account"
  type        = "k8s-service-account"
  driver_inputs = {
    values_string = jsonencode({
      "role_arn" = "$${resources.aws-role.outputs.arn}"
      "sa_name"  = "$${resources['config.sa-name-role-id'].outputs.sa_name}"
      "templates" = {
        "outputs"   = "name: {{ .driver.values.sa_name }}\n"
        "manifests" = <<END_OF_TEXT
service-account.yaml:
  location: namespace
  data: |
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: {{ .driver.values.sa_name }}
      annotations:
        eks.amazonaws.com/role-arn: {{ .driver.values.role_arn }}
END_OF_TEXT
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "example-k8s-service-account_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.example-k8s-service-account.id
  app_id                 = "example-break-a-loop-additional-resource"
}
