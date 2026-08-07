resource "humanitec_resource_definition" "example-aws-role" {
  driver_type = "humanitec/template"
  id          = "example-aws-role"
  name        = "example-aws-role"
  type        = "aws-role"
  driver_inputs = {
    values_string = jsonencode({
      "role_arn" = "$${resources['config.sa-name-role-id'].outputs.role_arn}"
      "sa_name"  = "$${resources['config.sa-name-role-id'].outputs.sa_name}"
      "templates" = {
        "outputs" = "arn: {{ .drivers.role_arn }}\n"
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "example-aws-role_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.example-aws-role.id
  app_id                 = "example-break-a-loop-additional-resource"
}
