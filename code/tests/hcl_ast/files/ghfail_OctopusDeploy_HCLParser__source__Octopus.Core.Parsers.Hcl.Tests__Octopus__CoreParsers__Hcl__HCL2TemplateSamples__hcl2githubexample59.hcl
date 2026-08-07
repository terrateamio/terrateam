#--- root/main.tf ---

#------------
#--- Provider
#------------
provider "aws" {
  region = "eu-west-1"
}

# account information
data "aws_caller_identity" "current" {}

#----------
#--- Locals
#----------
locals {
  account_id = data.aws_caller_identity.current.account_id
  bucket = "tfs3lambda-${data.aws_caller_identity.current.account_id}-${var.region}"
}

# deploy storage resources
module "storage" {
  source = "./storage"

  bucket = local.bucket

  enable_bucket_inventory = false
  enable_lifecycle        = false
  force_destroy           = true

  tags = {
    Name = format("%s_%s", var.project_name, local.bucket)
    project_name = var.project_name
  }
}

# deploy networking resources
module "networking" {
  source        = "./networking"

  region        = var.region
  project_name  = var.project_name
}

# deploy compute resources
module "compute" {
  source          = "./compute"

  account_id      = local.account_id
  region          = var.region
  project_name    = var.project_name
  key_name        = var.key_name
  public_key_path = var.public_key_path

  vpc1_id         = module.networking.vpc1_id
  subpub1_id      = module.networking.subpub1_id
  sgpub1_id       = module.networking.sgpub1_id

  bucket          = local.bucket
  bucket_arn      = module.storage.arn
}