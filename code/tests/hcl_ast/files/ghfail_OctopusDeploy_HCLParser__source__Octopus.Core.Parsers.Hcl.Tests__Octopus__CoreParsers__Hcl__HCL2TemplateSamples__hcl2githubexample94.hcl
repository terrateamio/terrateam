terraform {
  backend "gcs" {
    bucket = "patinando-net-int-tfstate"
    prefix = "service-edge"
  }
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "run_service_name" {
  type = string
}

variable "image" {
  type = string
}

module "cloud_run" {
  source = "git::https://github.com/CallePuzzle/terraform-google-cloud-run.git?ref=1.1.1"

  project = var.project
  region = var.region
  image = var.image
  run_service_name = var.run_service_name
}