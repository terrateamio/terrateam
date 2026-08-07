# Copyright 2022 Control Plan Corporation
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  required_version = ">= 1.1.0"
}

provider "aws" {
  region = var.aws-region
}

module "nlb-manager-lambda" {
  source = "../modules/nlb-manager-lambda"
  private-subnets = var.private-subnets
  public-subnet-cidr = var.public-subnet-cidr
  vpc-id = var.vpc-id
}

module "nlb" {
  vpc-id = var.vpc-id
  source = "../modules/nlb"
  name-prefix = var.name
  subnet-ids = var.subnet-ids
  include-all-resources-in-one-target-group = false
  include-all-resources-in-separate-target-groups = false
  internal = var.internal-nlb
}

module "nlb-manager-target" {
  for_each = var.targets
  source = "../modules/nlb-manager-target"
  name   = each.key
  nlb-arn = module.nlb.nlb-arn
  target = each.value
  lambda-arn = module.nlb-manager-lambda.lambda.arn
  lambda-name = module.nlb-manager-lambda.lambda.function_name
  polling-schedule-expression = var.polling-schedule-expression
}

module "endpoint-service" {
  source = "../modules/endpoint-service"
  name-prefix = var.name
  nlb-arn = module.nlb.nlb-arn
}