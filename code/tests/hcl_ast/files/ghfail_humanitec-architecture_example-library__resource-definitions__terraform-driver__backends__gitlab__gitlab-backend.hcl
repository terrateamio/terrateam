resource "humanitec_resource_definition" "example-terraform-gitlab-backend-s3" {
  driver_type = "humanitec/terraform"
  id          = "example-terraform-gitlab-backend-s3"
  name        = "example-terraform-gitlab-backend-s3"
  type        = "s3"
  driver_inputs = {
    values_string = jsonencode({
      "files" = {
        "main.tf" = <<END_OF_TEXT
resource "random_id" "thing" {
  byte_length = 8
}

output "bucket" {
  value = random_id.thing.hex
}
END_OF_TEXT
      }
    })
    secrets_string = jsonencode({
      "files" = {
        "backend.tf" = "$${resources['config.tf-runner'].outputs.backend_tf}"
      }
    })
  }
}


