terraform {
  required_providers {
    archive = {
      source = "hashicorp/archive"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.3"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.1"
    }
  }
  required_version = ">= 0.13"
}
