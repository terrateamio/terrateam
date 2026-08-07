resource "humanitec_resource_definition" "gcp-file-credentials" {
  driver_type    = "humanitec/terraform"
  id             = "gcp-file-credentials"
  name           = "gcp-file-credentials"
  type           = "gcs"
  driver_account = "$${resources['config.default#gcp-account'].account}"
  driver_inputs = {
    values_string = jsonencode({
      "credentials_config" = {
        "file" = "credentials.json"
      }
      "script" = <<END_OF_TEXT

variable "project_id" {}
variable "location" {}

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}
provider "google" {
  project     = var.project_id

  # The file is defined above. The provider will read a service account token from this file.
  credentials = "credentials.json"
}

output "name" {
  value = google_storage_bucket.bucket.name
}

resource "google_storage_bucket" "bucket" {
  name          = "$\{replace("$${context.res.id}", "/^.*\\./", "")}-standard-$${context.env.id}-$${context.app.id}-$${context.org.id}"
  location      = var.location
  force_destroy = true
}
END_OF_TEXT
      "variables" = {
        "location"   = "$${resources.config#gcp-account.outputs.location}"
        "project_id" = "$${resources.config#gcp-account.outputs.project_id}"
      }
    })
  }
}


