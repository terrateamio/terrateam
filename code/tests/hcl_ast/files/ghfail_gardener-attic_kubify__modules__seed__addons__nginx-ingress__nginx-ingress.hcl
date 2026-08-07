# Copyright (c) 2017 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

################################################################
# special handling for external-dns addon
################################################################

variable "config" {
  type = "map"
}
variable "active" {
  type = "string"
}

variable "versions" {
  type = "map"
}
variable "standard" {
  type = "map"
}
variable "selected" {
  type = "list"
}

variable "cluster-lb" {
  default = "false"
}

variable "namespace" {
  default = "nginx-ingress"
}

variable "vip_ingress" {
}

module "versions" {
  source = "../../../versions"
  versions = "${var.versions}"
}

module "addon" {
  source = "../../../flag"
  option = "${var.active}"
}
module "cluster-lb" {
  source = "../../../flag"
  option = "${var.cluster-lb}"
}

locals {
    dns_annotation = "external-dns.alpha.kubernetes.io/hostname: \"*.${var.standard["ingress"]}\""
}

module "generated" {
  source = "../../../condmap"
  if = "${module.cluster-lb.value}"
  then = { # load balancer/DNS provided in cluster
    annotations = "${indent(4,local.dns_annotation)}"
    service_type = "LoadBalancer"
    publish_service = "- --publish-service=${var.namespace}/nginx-ingress-controller"
    host_network = "false" 
  }
  else = { # load balancer/DNS provided externally
    annotations = ""
    service_type = "ClusterIP"
    publish_service = "- --publish-status-address=${var.vip_ingress}"
    host_network = "true"
  }
}

locals {
  defaults = {
    namespace = "${var.namespace}"
    version = "${module.versions.nginx_version}"
  }

  generated = "${module.generated.value}"

  dummy = {
    namespace = "${var.namespace}"
    annotations = ""
    service_type = ""
    publish_service = ""
    host_network = ""
  }

  config = "${merge(local.defaults,var.config)}"
}

#
# addon module api
#
output "dummy" {
  value = "${local.dummy}"
}
output "defaults" {
  value="${local.defaults}"
}
output "generated" {
  value="${local.generated}"
}

output "manifests" {
  value="${path.module}/templates/manifests"
}

output "deploy" {
  value=""
}
