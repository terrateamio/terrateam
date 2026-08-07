resource "humanitec_resource_definition" "s3-read-only" {
  driver_type = "humanitec/echo"
  id          = "s3-read-only"
  name        = "s3-read-only"
  type        = "s3"
  driver_inputs = {
    values_string = jsonencode({
      "bucket" = "$${resources['s3.concrete'].outputs.bucket}"
    })
  }

  provision = {
    "aws-policy.s3-read-only" = {
      is_dependent     = false
      match_dependents = true
    }
  }
}

resource "humanitec_resource_definition_criteria" "s3-read-only_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.s3-read-only.id
  app_id                 = "example-delegator"
  class                  = "read-only"
}
