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

variable "iaas_config" {
  type = "map"
}
variable "access_info" {
  type = "map"
}
variable "etcd_backup" {
  type = "map"
}

module "cluster"{
  source = "../cluster"

  cluster_name = "${var.cluster_name}"
  cluster_type = "${var.cluster_type}"
  service_cidr = "${var.service_cidr}"
  pod_cidr = "${var.pod_cidr}"
  platform = "${var.platform}"
  hosted_zone_domain = "${module.hosted_zone_domain.value}"
  base_domain  = "${module.base_domain.value}"
  domain_name  = "${module.domain_name.value}"
  additional_domains = "${var.additional_domains}"
  additional_api_domains = "${var.additional_api_domains}"
  pull_secret = "${module.pull_secret.content}"
  master_count = "${module.master_config.count}"
  selfhosted_etcd = "${var.selfhosted_etcd}"
}

module "root_certs" {
  source = "../file"
  path = "${var.root_certs_file}"
}
module "pull_secret" {
  source = "../file"
  path = "${var.pull_secret_file}"
}

module "bastion_config" {
  source = "../access/node_config"
  node_config = "${var.bastion}"

  volume_size = "0"

  flavor_name = "${module.bastion_vm.flavor_name}"
  image_name = "${module.bastion_vm.image_name}"
  user_name = "${var.bastion_user}"

  defaults = {
    update_mode = "${var.node_update_mode}"
    count = "1"
    assign_fips = "true"
    user_name = "ubuntu"
  }
}

module "iaas" {
  source = "../../variants/current/modules/iaas"

  iaas_config    = "${var.iaas_config}"

  cluster_name = "${var.cluster_name}"
  cluster_type = "${var.cluster_type}"

  gen_dir = "${module.cluster.gen_dir}"
  prefix = "${module.cluster.prefix}"

  subnet_cidr = "${var.subnet_cidr}"
  dns_nameservers = "${var.dns_nameservers}"

  use_bastion = "${module.use_bastion.value}"
  bastion = "${module.bastion_config.node_config}"
}

data "archive_file" "helper_scripts" {
  type        = "zip"
  output_path = "${module.cluster.gen_dir}/helper.zip"
  source_dir = "${path.module}/resources/bin"
}

module "addon_dns" {
  source = "../condmap"
  if = "${module.worker_config.count == 0}"
  then = {
    external_dns = { }
  }
  else = { }
}
module "addon_machine" {
  source = "../condmap"
  if = "${module.worker_config.count == 0}"
  then = {
    machine = {
      worker_count = 1
    }
  }
  else = { }
}

module "seed" {
  source = "../seed"

  cluster_name = "${var.cluster_name}"
  cluster_type = "${var.cluster_type}"
  cluster-lb = "${var.cluster-lb || module.worker_config.count == 0}"
  addons = "${merge(module.addon_dns.value, module.addon_machine.value, var.addons)}"

  gen_dir = "${module.cluster.gen_dir}"

  domain_name = "${module.cluster.domain_name}"
  ingress_base_domain = "${module.cluster.ingress_base_domain}"
  api_dns_name = "${module.cluster.api}"

  tls_dir    = "${module.cluster.tls_dir}"
  tls_kubelet = "${module.cluster.tls_kubelet}"
  tls_apiserver = "${module.cluster.tls_apiserver}"
  tls_aggregator = "${module.cluster.tls_aggregator}"
  tls_etcd = "${module.cluster.tls_etcd}"
  tls_etcd_client = "${module.cluster.tls_etcd_client}"

  pull_secret_b64 = "${module.cluster.pull_secret_b64}"

  oidc_issuer_subdomain = "${var.oidc_issuer_subdomain}"
  oidc_issuer_domain = "${var.oidc_issuer_domain}"
  oidc_client_id = "${var.oidc_client_id}"
  oidc_username_claim = "${var.oidc_username_claim}"
  oidc_groups_claim = "${var.oidc_groups_claim}"
  oidc_ca_file = "${var.oidc_ca_file}"
  oidc_use_cluster_ca = "${var.oidc_use_cluster_ca}"


  master_count = "${module.master_config.count}"
  nodes_cidr = "${module.iaas.nodes_cidr}"
  service_cidr = "${var.service_cidr}"
  pod_cidr = "${var.pod_cidr}"
  cloud_provider = "${module.iaas.cloud_provider}"
  service_account_public_key_pem = "${module.cluster.service_account_public_key_pem}"
  service_account_private_key_pem = "${module.cluster.service_account_private_key_pem}"
  dns_service_ip = "${module.cluster.dns_service_ip}"
  bootstrap_etcd_service_ip = "${module.cluster.bootstrap_etcd_service_ip}"
  etcd_service_ip = "${module.cluster.etcd_service_ip}"
  etcd_service_name = "${module.cluster.etcd_service_name}"
  host_ssl_certs_dir = "${var.host_ssl_certs_dir}"

  assets_inst_dir = "${module.cluster.assets_inst_dir}"
  recover_redeploy = "${var.recover_redeploy}"
  etcd_backup_file = "${module.recover_cluster.if_active ? var.etcd_backup_file : ""}"
  etcd_backup = "${var.etcd_backup}"
  selfhosted_etcd = "${var.selfhosted_etcd}"

  event_ttl = "${var.event_ttl}"
  use_lbaas = "${var.use_lbaas}"
  deploy_tiller = "${var.deploy_tiller}"

  addon_dirs = "${module.iaas.addon-dirs}"
  addon_trigger = "${module.iaas.addon-trigger}"

  dashboard_user = "${var.dashboard_user}"
  dashboard_password = "${var.dashboard_password}"
  default_password = "${module.iaas.default_password}"
  dashboard_creds = "${var.dashboard_creds}"

  versions = "${module.versions.versions}"
  vm_version = "${module.recovery_version.value}"

  access_info = "${var.access_info}"
  cluster_info = "${module.cluster.cluster-info}"

  etcd_names = "${module.cluster.etcd_names}"
  etcd_domains = "${module.cluster.etcd_domains}"
  etcd_base_domain = "${module.cluster.etcd_base_domain}"
  dns = "${var.dns}"
  identity_domain = "${module.cluster.identity}"

  iaas_config = "${var.iaas_config}"
  worker_info = "${module.worker.vm_info}"

  vip_ingress = "${module.vip_nginx.value}"
}

output "gen_dir" {
  value = "${module.cluster.gen_dir}"
}

output "etcd_service_ip" {
  value = "${module.cluster.etcd_service_ip}"
}

output "access_info" {
  value = "${var.access_info}"
}
