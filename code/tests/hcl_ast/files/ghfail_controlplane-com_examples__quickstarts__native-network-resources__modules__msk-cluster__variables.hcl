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

variable "name-prefix" {
  type = string
  description = "The name of the MSK cluster. This will also be used on associated VPC resources like subnets and security groups."
}

variable "cluster-tags" {
  type = map(string)
  description = "A map containing labels for the MSK cluster"
  default = { }
}

variable "vpc-cidr" {
  type = string
  default = "11.0.0.0/16"
  description = "The CIDR for the VPC containing the MSK cluster"
}

variable "subnet-cidr-list" {
  type = list(string)
  default = ["11.0.0.0/24", "11.0.1.0/24", "11.0.2.0/24"]
  description = "The CIDRs for the subnets containing the MSK brokers."
}

variable "broker-instance-type" {
  type = string
  default = "kafka.m5.large"
  description = "Instance type for brokers"
}

variable "broker-storage-capacity" {
  type = number
  default = 1000
  description = "Storage capacity on broker instances in GB"
}

variable "broker-count" {
  type = number
  default = 3
  description = "The desired total number of broker nodes in the kafka cluster. It must be a multiple of 3."
}
