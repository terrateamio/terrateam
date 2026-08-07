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
  description = "A name summarizing the resources to be fronted by the NLB / endpoint service"
}

variable "internal" {
  type = bool
  description = "True if the NLB should be internal only. False if it should be exposed to the internet."
  default = true
}

variable "vpc-id" {
  type = string
  description = "The VPC hosting the network resources"
}

variable "tags" {
  type = map(string)
  description = "A map containing labels for all taggable resources that are created by this module"
  default = {}
}

variable "subnet-ids" {
  type = list(string)
  description = "The list of subnet ids "
}

variable "targets" {
  type = map(object({
    ip-address = string
    internal-port = number
    external-port = number
  }))
  default = {}
  description = "A map of objects containing listener ip addresses and port numbers"
}

variable "include-all-resources-in-separate-target-groups"{
  type = bool
  default = true
  description = "If this is true one listener, target group, and target will be included for every resource"
}

variable "include-all-resources-in-one-target-group" {
  type = bool
  default = true
  description = "If this is true, a listener and target group containing all of the listed targets will be included."
}