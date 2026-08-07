resource "humanitec_resource_definition" "s3-admin" {
  driver_type = "humanitec/echo"
  id          = "s3-admin"
  name        = "s3-admin"
  type        = "s3"
  driver_inputs = {
    values_string = jsonencode({
      "bucket" = "$${resources['s3.concrete'].outputs.bucket}"
    })
  }

  provision = {
    "aws-policy.s3-admin" = {
      is_dependent     = false
      match_dependents = true
    }
  }
}

resource "humanitec_resource_definition_criteria" "s3-admin_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.s3-admin.id
  app_id                 = "example-delegator"
  class                  = "admin"
}
