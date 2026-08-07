# Copyright 2022 Control Plane Corporation
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

variable "name" {
  type = string
  default = "cpln-nlb-manager"
  description = "The name of the native network resource configuration. Associated resources will use this name as a prefix"
}

variable "vpc-id" {
  type = string
  description = "The name of the VPC in which the lambda function will run"
}

variable "public-subnet-cidr" {
  type = string
  description = "A CIDR that will host a NAT gateway to allow the lambda function internet access"
}

variable "private-subnets" {
  type = map(object({
    CIDR = string
    availability-zone = string 
  }))
  description = "A list of subnets in which the lambda will execute"
}

variable "aws-region" {
  type = string
  description = "The name of the AWS region containing the network resources you wish to expose."
  default = "us-east-2"
}