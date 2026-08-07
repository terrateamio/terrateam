resource "humanitec_resource_definition" "base-env" {
  driver_type = "humanitec/template"
  id          = "base-env"
  name        = "base-env"
  type        = "base-env"
  driver_inputs = {
    values_string = jsonencode({
      "templates" = {
        "manifests" = "secretstore.yaml:\n  location: namespace\n  data:\n    apiVersion: humanitec.io/v1alpha1\n    kind: SecretStore\n    metadata:\n      # Use this line for context-agnostic naming:\n      name: my-local-gsm\n      # Use this line instead for context-specific naming:\n      # name: $${context.app.id}-$${context.env.id}\n    spec:\n      # Configure the secret store according to its type\n      # This example shows a Google Cloud Secret Manager\n      gcpsm:\n        auth: {}\n        projectID: $${resources['config.secretstore'].outputs.project_id}"
      }
    })
  }
}

resource "humanitec_resource_definition_criteria" "base-env_criteria_0" {
  resource_definition_id = resource.humanitec_resource_definition.base-env.id
  app_id                 = "my-secretstore-app"
}
