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

variable "dns_access_info" {
  type = "map"
}
variable "domain_filters" {
  default = ""
}


variable "namespace" {
  default = "kubify-dns"
}

module "versions" {
  source = "../../../versions"
  versions = "${var.versions}"
}

module "addon" {
  source = "../../../flag"
  option = "${var.active}"
}


locals {
  provider_map = {
    aws = "aws"
    route53 = "aws"
  }

  defaults = {
    namespace = "${var.namespace}"
    provider = "${local.provider_map[lookup(var.dns_access_info,"dns_type","aws")]}"
    domain-filters = "${var.domain_filters}"
    zone-filters = ""
    version = "${module.versions.external_dns_version}"
    image = "${module.versions.external_dns_image}"
  }

  dummy = {
    namespace = "${var.namespace}"
    image = ""
  }

  config = "${merge(local.defaults,var.config)}"
}

module "vars" {
  source = "../../../condmap"
  if = "${var.active}"
  then = "${merge(local.defaults,var.dns_access_info,var.config)}"
  else = "${local.dummy}"
}

locals {
  secret_vars = {
    access_key_b64 = "${base64encode(lookup(module.vars.value,"access_key",""))}"
    secret_key_b64 = "${base64encode(lookup(module.vars.value,"secret_key",""))}"
  }
}

data "template_file" "secret" {
  count = "${module.addon.if_active}"
  template= "${file("${path.module}/templates/types/${local.config["provider"]}/secret.yaml")}"
  vars = "${merge(local.secret_vars,module.vars.value)}"
}
module "secret" {
  source = "../../../optrsc"
  value = "${data.template_file.secret.*.rendered}"
}

data "template_file" "env" {
  count = "${module.addon.if_active}"
  template= "${file("${path.module}/templates/types/${local.config["provider"]}/env.yaml")}"
  vars = "${module.vars.value}"
}
module "env" {
  source = "../../../optrsc"
  value = "${data.template_file.env.*.rendered}"
}

locals {
  generated = {
    secret = "${module.secret.value}"
    env = "${indent(8,module.env.value)}"
    domain_filters ="${indent(8,join("\n",formatlist("- --basedomain-filter=%s", compact(split(",",lookup(local.config,"domain-filters",""))))))}"
    zone_filters ="${indent(8,join("\n",formatlist("- --domain-filter=%s", compact(split(",",lookup(local.config,"zone-filters",""))))))}"
  }
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
