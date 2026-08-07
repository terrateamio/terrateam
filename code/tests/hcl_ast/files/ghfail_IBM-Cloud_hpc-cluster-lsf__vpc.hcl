###################################################
# Copyright (C) IBM Corp. 2021 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

# IBM Cloud Provider
# Docs are available here, https://cloud.ibm.com/docs/terraform?topic=terraform-tf-provider#store_credentials
# Download IBM Cloud Provider binary from release page. https://github.com/IBM-Cloud/terraform-provider-ibm/releases
# And copy it to $HOME/.terraform.d/plugins/terraform-provider-ibm_v1.2.4

module "vpc" {
  source                        = "./resources/ibmcloud/network/vpc"
  count                         = var.vpc_name == "" ? 1 : 0
  name                          = "${var.cluster_prefix}-vpc"
  resource_group                = data.ibm_resource_group.rg.id
  vpc_address_prefix_management = "manual"
  tags                          = local.tags
}

// This module creates a vpc_address_prefix as we are now using custom CIDR range for VPC creation
module "vpc_address_prefix" {
  count        = var.vpc_name == "" ? 1 : 0
  source       = "./resources/ibmcloud/network/vpc_address_prefix"
  vpc_id       = data.ibm_is_vpc.vpc.id
  address_name = format("%s-addr", var.cluster_prefix)
  zones        = var.zone
  cidr_block   = var.vpc_cidr_block
}

module "public_gateway" {
  source         = "./resources/ibmcloud/network/public_gateway"
  count          = var.vpc_name == "" ? 1 : 0
  name           = "${var.cluster_prefix}-gateway"
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = var.zone
  resource_group = data.ibm_resource_group.rg.id
  tags           = local.tags
}

module "login_subnet" {
  count             = (var.cluster_subnet_id == "" && var.login_subnet_id == "") ? 1 : 0
  source            = "./resources/ibmcloud/network/login_subnet"
  login_subnet_name = "${var.cluster_prefix}-login-subnet"
  vpc               = data.ibm_is_vpc.vpc.id
  zone              = data.ibm_is_zone.zone.name
  ipv4_cidr_block   = var.vpc_cluster_login_private_subnets_cidr_blocks[0]
  resource_group    = data.ibm_resource_group.rg.id
  tags              = local.tags
  depends_on        = [module.vpc_address_prefix]
}

module "subnet" {
  count                                   = var.cluster_subnet_id == "" ? 1 : 0
  source                                  = "./resources/ibmcloud/network/subnet"
  subnet_name                             = "${var.cluster_prefix}-subnet"
  vpc                                     = data.ibm_is_vpc.vpc.id
  zone                                    = data.ibm_is_zone.zone.name
  vpc_cluster_private_subnets_cidr_blocks = var.vpc_cluster_private_subnets_cidr_blocks[0]
  public_gateway                          = var.vpc_name == "" ? module.public_gateway[0].public_gateway_id : (length(local.existing_pgw_id) > 0 ? local.existing_pgw_id[0] : null)
  resource_group                          = data.ibm_resource_group.rg.id
  tags                                    = local.tags
  depends_on                              = [module.vpc_address_prefix]
}

module "login_sg" {
  source         = "./resources/ibmcloud/security/login_sg"
  name           = "${var.cluster_prefix}-login-sg"
  vpc            = data.ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.rg.id
  tags           = local.tags
}

module "login_inbound_security_rules" {
  source             = "./resources/ibmcloud/security/login_sg_inbound_rule"
  remote_allowed_ips = var.remote_allowed_ips
  group              = module.login_sg.sec_group_id
  depends_on         = [module.login_sg]
}

module "login_outbound_security_rule" {
  source = "./resources/ibmcloud/security/login_sg_outbound_rule"
  group  = module.login_sg.sec_group_id
  remote = module.sg.sg_id
}

// This module used to create security group rule to allow outbound traffic within VPC
module "login_outbound_vpc_rules" {
  source    = "./resources/ibmcloud/security/security_group_outbound_rules"
  group     = module.login_sg.sec_group_id
  remote    = var.vpc_name == "" ? var.vpc_cidr_block[0] : data.ibm_is_vpc_address_prefixes.existing_vpc.address_prefixes[0].cidr
  direction = "outbound"
}

module "sg" {
  source         = "./resources/ibmcloud/security/security_group"
  sec_group_name = "${var.cluster_prefix}-sg"
  vpc            = data.ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.rg.id
  tags           = local.tags
}

module "inbound_sg_rule" {
  source = "./resources/ibmcloud/security/security_group_inbound_rule"
  group  = module.sg.sg_id
  remote = module.login_sg.sec_group_id
}

module "inbound_sg_ingress_all_local_rule" {
  source = "./resources/ibmcloud/security/security_group_ingress_all_local"
  group  = module.sg.sg_id
  remote = module.sg.sg_id
}

module "outbound_sg_rule" {
  source = "./resources/ibmcloud/security/security_group_outbound_rule"
  group  = module.sg.sg_id
}

module "schematics_sg_tcp_rule" {
  source            = "./resources/ibmcloud/security"
  security_group_id = module.login_sg.sec_group_id
  sg_direction      = "inbound"
  remote_ip_addr    = tolist([chomp(data.http.fetch_myip.response_body)])
  depends_on        = [module.login_sg]
}

// The module is used to create the login/bastion node to access all other nodes in the cluster
module "bastion_vsi" {
  source             = "./resources/ibmcloud/compute/login_vsi"
  vsi_name           = "${var.cluster_prefix}-bastion"
  image              = data.ibm_is_image.stock_image.id
  profile            = data.ibm_is_instance_profile.login.name
  vpc                = data.ibm_is_vpc.vpc.id
  zone               = data.ibm_is_zone.zone.name
  keys               = local.ssh_key_id_list
  user_data          = data.template_file.bastion_user_data.rendered
  resource_group     = data.ibm_resource_group.rg.id
  tags               = local.tags
  subnet_id          = var.login_subnet_id != "" ? var.login_subnet_id : (length(module.login_subnet) > 0 ? module.login_subnet[0].login_subnet_id : null)
  security_group     = [module.login_sg.sec_group_id]
  encryption_key_crn = local.encryption_key_crn
  depends_on         = [module.login_ssh_key, module.login_inbound_security_rules, module.login_outbound_security_rule]
}

// The module is used to create login node.
module "login_vsi" {
  source             = "./resources/ibmcloud/compute/management_node_vsi"
  count              = 1
  vsi_name           = "${var.cluster_prefix}-login"
  image              = local.compute_image_mapping_entry_found ? local.new_compute_image_id : data.ibm_is_image.compute[0].id
  profile            = data.ibm_is_instance_profile.management_host.name
  vpc                = data.ibm_is_vpc.vpc.id
  zone               = data.ibm_is_zone.zone.name
  keys               = local.ssh_key_id_list
  resource_group     = data.ibm_resource_group.rg.id
  user_data          = "${data.template_file.login_user_data.rendered} ${file("${path.module}/scripts/login_vsi.sh")}"
  subnet_id          = var.login_subnet_id != "" ? var.login_subnet_id : (length(module.login_subnet) > 0 ? module.login_subnet[0].login_subnet_id : null)
  security_group     = [module.sg.sg_id]
  tags               = local.tags
  instance_id        = local.dns_instance_id
  zone_id            = module.dns_zone.id
  dns_domain         = var.dns_domain
  encryption_key_crn = local.encryption_key_crn
  depends_on = [
    module.bastion_vsi,
  ]
}

module "cluster_file_share" {
  source             = "./resources/ibmcloud/file_share/"
  name               = "${var.cluster_prefix}-cluster-share"
  resource_group     = data.ibm_resource_group.rg.id
  size               = local.cluster_file_share_size
  iops               = 1000
  zone               = data.ibm_is_zone.zone.name
  subnet_id          = var.cluster_subnet_id != "" ? var.cluster_subnet_id : module.subnet[0].subnet_id
  security_groups    = [module.sg.sg_id]
  tags               = local.tags
  encryption_key_crn = local.encryption_key_crn
}

module "custom_file_share" {
  source             = "./resources/ibmcloud/file_share/"
  count              = length(var.custom_file_shares)
  name               = "${var.cluster_prefix}-custom-share-${count.index + 1}"
  resource_group     = data.ibm_resource_group.rg.id
  size               = var.custom_file_shares[count.index]["size"]
  iops               = var.custom_file_shares[count.index]["iops"]
  zone               = data.ibm_is_zone.zone.name
  subnet_id          = var.cluster_subnet_id != "" ? var.cluster_subnet_id : module.subnet[0].subnet_id
  security_groups    = [module.sg.sg_id]
  tags               = local.tags
  encryption_key_crn = local.encryption_key_crn
}

// The resource is used to validate the existing LDAP server connection.
resource "null_resource" "validate_ldap_server_connection" {
  count = var.enable_ldap == true && var.ldap_server != "null" ? 1 : 0
  connection {
    type        = "ssh"
    user        = "root"
    private_key = module.login_ssh_key.private_key
    host        = module.login_fip.floating_ip_address
  }
  provisioner "remote-exec" {
    inline = [
      "if openssl s_client -connect '${var.ldap_server}:389' </dev/null 2>/dev/null | grep -q 'CONNECTED'; then echo 'The connection to the existing LDAP server ${var.ldap_server} was successfully established.'; else echo 'The connection to the existing LDAP server ${var.ldap_server} failed, please establish it.'; exit 1; fi",
    ]
  }

  depends_on = [
    module.login_vsi
  ]
}


module "ldap_vsi" {
  source             = "./resources/ibmcloud/compute/ldap_vsi"
  count              = var.enable_ldap == true && var.ldap_server == "null" ? 1 : 0
  name               = "${var.cluster_prefix}-ldap-1"
  image              = local.ldap_instance_image_id
  profile            = var.ldap_vsi_profile
  vpc                = data.ibm_is_vpc.vpc.id
  zone               = data.ibm_is_zone.zone.name
  keys               = local.ssh_key_id_list
  resource_group     = data.ibm_resource_group.rg.id
  user_data          = "${data.template_file.ldap_user_data[0].rendered} ${file("${path.module}/scripts/ldap_user_data.sh")}"
  subnet_id          = var.cluster_subnet_id != "" ? var.cluster_subnet_id : module.subnet[0].subnet_id
  security_group     = [module.sg.sg_id]
  instance_id        = local.dns_instance_id
  zone_id            = module.dns_zone.id
  dns_domain         = var.dns_domain
  encryption_key_crn = local.encryption_key_crn
  tags               = local.tags
  depends_on = [
    module.login_ssh_key,
    module.inbound_sg_rule,
    module.inbound_sg_ingress_all_local_rule,
    module.outbound_sg_rule,
    module.bastion_vsi
  ]
}

module "management_host" {
  source             = "./resources/ibmcloud/compute/management_node_vsi"
  count              = 1
  vsi_name           = "${var.cluster_prefix}-mgmt-1"
  image              = local.image_mapping_entry_found ? local.new_image_id : data.ibm_is_image.image[0].id
  profile            = data.ibm_is_instance_profile.management_host.name
  vpc                = data.ibm_is_vpc.vpc.id
  zone               = data.ibm_is_zone.zone.name
  keys               = local.ssh_key_id_list
  resource_group     = data.ibm_resource_group.rg.id
  user_data          = "${data.template_file.management_host_user_data.rendered} ${file("${path.module}/scripts/LSF_management_static_server.sh")} ${local.management_host_reboot_str}"
  subnet_id          = var.cluster_subnet_id != "" ? var.cluster_subnet_id : module.subnet[0].subnet_id
  security_group     = [module.sg.sg_id]
  instance_id        = local.dns_instance_id
  zone_id            = module.dns_zone.id
  dns_domain         = var.dns_domain
  tags               = local.tags
  encryption_key_crn = local.encryption_key_crn
  depends_on = [
    module.login_ssh_key,
    module.inbound_sg_rule,
    module.inbound_sg_ingress_all_local_rule,
    module.outbound_sg_rule,
    module.login_vsi,
    null_resource.validate_ldap_server_connection
  ]
}

resource "null_resource" "entitlement_check" {
  count = local.image_mapping_entry_found ? 1 : 0
  connection {
    type                = "ssh"
    host                = module.management_host[0].primary_network_interface
    user                = "root"
    private_key         = module.login_ssh_key.private_key
    bastion_host        = module.login_fip.floating_ip_address
    bastion_user        = "root"
    bastion_private_key = module.login_ssh_key.private_key
    timeout             = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "python3 /opt/IBM/cloud_entitlement/entitlement_check.py --products ${local.products} --icns ${var.ibm_customer_number}"
    ]
  }
  depends_on = [module.management_host, module.login_fip, module.login_vsi]
}

module "management_host_candidate" {
  source             = "./resources/ibmcloud/compute/management_host_candidates"
  count              = var.management_node_count - 1
  vsi_name           = "${var.cluster_prefix}-mgmt-${count.index + 2}"
  image              = local.image_mapping_entry_found ? local.new_image_id : data.ibm_is_image.image[0].id
  profile            = data.ibm_is_instance_profile.management_host.name
  vpc                = data.ibm_is_vpc.vpc.id
  zone               = data.ibm_is_zone.zone.name
  keys               = local.ssh_key_id_list
  resource_group     = data.ibm_resource_group.rg.id
  user_data          = "${data.template_file.management_host_user_data.rendered} ${file("${path.module}/scripts/LSF_management_static_candidate_server.sh")} ${local.management_host_reboot_str}"
  subnet_id          = var.cluster_subnet_id != "" ? var.cluster_subnet_id : module.subnet[0].subnet_id
  security_group     = [module.sg.sg_id]
  instance_id        = local.dns_instance_id
  zone_id            = module.dns_zone.id
  dns_domain         = var.dns_domain
  tags               = local.tags
  encryption_key_crn = local.encryption_key_crn
  depends_on = [
    module.management_host,
    module.inbound_sg_ingress_all_local_rule,
    module.inbound_sg_rule,
    module.outbound_sg_rule,
    null_resource.entitlement_check,
    module.login_vsi,
    null_resource.validate_ldap_server_connection
  ]
}

module "spectrum_scale_storage" {
  source             = "./resources/ibmcloud/compute/scale_storage_vsi"
  count              = var.spectrum_scale_enabled == true ? var.scale_storage_node_count : 0
  vsi_name           = "${var.cluster_prefix}-spectrum-storage-${count.index}"
  image              = local.scale_image_mapping_entry_found ? local.scale_image_id : data.ibm_is_image.scale_image[0].id
  profile            = data.ibm_is_instance_profile.spectrum_scale_storage.name
  vpc                = data.ibm_is_vpc.vpc.id
  zone               = data.ibm_is_zone.zone.name
  keys               = local.ssh_key_id_list
  resource_group     = data.ibm_resource_group.rg.id
  user_data          = "${data.template_file.metadata_startup_script.rendered} ${file("${path.module}/scripts/LSF_spectrum_storage.sh")}"
  tags               = local.tags
  subnet_id          = var.cluster_subnet_id != "" ? var.cluster_subnet_id : module.subnet[0].subnet_id
  instance_id        = local.dns_instance_id
  zone_id            = module.dns_zone.id
  dns_domain         = var.dns_domain
  security_group     = [module.sg.sg_id]
  encryption_key_crn = local.encryption_key_crn
  depends_on         = [module.login_vsi, module.management_host, module.management_host_candidate, module.inbound_sg_rule, module.inbound_sg_ingress_all_local_rule, module.outbound_sg_rule]
}

// The module is used to create the compute vsi instance based on the type of node_type required for deployment
module "worker_vsi" {
  source             = "./resources/ibmcloud/compute/worker_vsi"
  count              = var.worker_node_min_count
  vsi_name           = "${var.cluster_prefix}-worker-${count.index}"
  image              = local.compute_image_mapping_entry_found ? local.new_compute_image_id : data.ibm_is_image.compute[0].id
  profile            = data.ibm_is_instance_profile.worker.name
  vpc                = data.ibm_is_vpc.vpc.id
  zone               = data.ibm_is_zone.zone.name
  keys               = local.ssh_key_id_list
  resource_group     = data.ibm_resource_group.rg.id
  user_data          = "${data.template_file.worker_user_data.rendered} ${file("${path.module}/scripts/LSF_dynamic_workers.sh")} ${local.worker_reboot_str}"
  dedicated_host     = var.dedicated_host_enabled ? module.dedicated_host[var.dedicated_host_placement == "spread" ? count.index % local.dh_count : floor(count.index / local.dh_worker_count)].dedicated_host_id : null
  subnet_id          = var.cluster_subnet_id != "" ? var.cluster_subnet_id : module.subnet[0].subnet_id
  instance_id        = local.dns_instance_id
  zone_id            = module.dns_zone.id
  dns_domain         = var.dns_domain
  security_group     = [module.sg.sg_id]
  tags               = local.tags
  encryption_key_crn = local.encryption_key_crn
  depends_on = [
    module.management_host,
    module.management_host_candidate,
    module.inbound_sg_ingress_all_local_rule,
    module.inbound_sg_rule,
    module.outbound_sg_rule,
    null_resource.entitlement_check
  ]
}

module "login_fip" {
  source            = "./resources/ibmcloud/network/floating_ip"
  floating_ip_name  = "${var.cluster_prefix}-login-fip"
  target_network_id = module.bastion_vsi.primary_network_interface
  resource_group    = data.ibm_resource_group.rg.id
  tags              = local.tags
}

module "kms" {
  source                             = "./resources/ibmcloud/network/kms"
  resource_group                     = data.ibm_resource_group.rg.id
  enable_customer_managed_encryption = var.enable_customer_managed_encryption
  kms_instance_id                    = var.kms_instance_id
  kms_key_name                       = var.kms_key_name
  resource_instance_name             = var.cluster_prefix
  region                             = local.region_name
  tags                               = local.tags
}

module "dns_service" {
  source                 = "./resources/ibmcloud/network/dns_service"
  resource_group_id      = data.ibm_resource_group.rg.id
  dns_instance_id        = var.dns_instance_id
  resource_instance_name = var.cluster_prefix
  tags                   = local.tags
}

module "dns_zone" {
  source         = "./resources/ibmcloud/network/dns_zone"
  dns_domain     = var.dns_domain
  dns_service_id = local.dns_instance_id
  description    = "name of DNS zone"
  dns_label      = var.cluster_prefix
}

module "dns_permitted_network" {
  source      = "./resources/ibmcloud/network/dns_permitted_network"
  instance_id = local.dns_instance_id
  zone_id     = module.dns_zone.*.id[0]
  vpc_crn     = data.ibm_is_vpc.vpc.crn
}

module "custom_resolver" {
  source                 = "./resources/ibmcloud/network/dns_resolver"
  customer_resolver_name = format("%s-custom-resolver", var.cluster_prefix)
  instance_guid          = local.dns_instance_id
  dns_custom_resolver_id = var.dns_custom_resolver_id
  subnet_crn             = local.subnet_crn
  description            = "DNS resolver"
  depends_on             = [module.bastion_vsi, module.worker_vsi, module.login_vsi, module.management_host, module.management_host_candidate, module.spectrum_scale_storage, module.ldap_vsi]

}

module "vpn" {
  source         = "./resources/ibmcloud/network/vpn"
  count          = var.vpn_enabled ? 1 : 0
  name           = "${var.cluster_prefix}-vpn"
  resource_group = data.ibm_resource_group.rg.id
  subnet         = var.login_subnet_id != "" ? var.login_subnet_id : (length(module.login_subnet) > 0 ? module.login_subnet[0].login_subnet_id : null)
  mode           = "policy"
  tags           = local.tags
}

module "vpn_connection" {
  source            = "./resources/ibmcloud/network/vpn_connection"
  count             = var.vpn_enabled ? 1 : 0
  name              = "${var.cluster_prefix}-vpn-conn"
  vpn_gateway       = module.vpn[count.index].vpn_gateway_id
  vpn_peer_address  = var.vpn_peer_address
  vpn_preshared_key = var.vpn_preshared_key
  admin_state_up    = true
  local_cidrs       = var.login_subnet_id != "" ? [data.ibm_is_subnet.existing_login_subnet[0].ipv4_cidr_block] : [module.login_subnet[0].ipv4_cidr_block]
  peer_cidrs        = local.peer_cidr_list
}

#create iam authorisation between cos bucket and vpc flow logs
module "iam_vpc_flow_logs" {
  source                         = "./resources/ibmcloud/network/vpc_flow_log_iam"
  count                          = (var.enable_vpc_flow_logs) ? 1 : 0
  existing_storage_instance_guid = var.existing_cos_instance_guid
}

# Create VPC flow logs collector
module "vpc_flow_log" {
  count             = (var.enable_vpc_flow_logs) ? 1 : 0
  source            = "./resources/ibmcloud/network/vpc_flow_log"
  vpc_flow_log_name = "${var.cluster_prefix}-logs"
  target_id         = data.ibm_is_vpc.vpc.id
  is_active         = var.is_flow_log_collector_active
  storage_bucket    = var.existing_storage_bucket_name
  resource_group    = data.ibm_resource_group.rg.id
  tags              = local.tags
}

module "ingress_vpn" {
  source = "./resources/ibmcloud/security/vpn_ingress_security_rule"
  count  = length(local.peer_cidr_list)
  group  = module.login_sg.sec_group_id
  remote = local.peer_cidr_list[count.index]
}

module "dedicated_host_group" {
  source         = "./resources/ibmcloud/dedicated_host_group"
  count          = local.dh_count > 0 ? 1 : 0
  name           = "${var.cluster_prefix}-dh"
  class          = local.dh_profile.class
  family         = local.dh_profile.family
  zone           = data.ibm_is_zone.zone.name
  resource_group = data.ibm_resource_group.rg.id
}
// The module is used to create the dedicated host for all the worker nodes to join the host
module "dedicated_host" {
  source         = "./resources/ibmcloud/dedicated_host"
  count          = local.dh_count
  name           = "${var.cluster_prefix}-dh-${count.index}"
  profile        = local.dh_profile.name
  host_group     = module.dedicated_host_group[0].dedicate_host_group_id
  resource_group = data.ibm_resource_group.rg.id
}

module "login_ssh_key" {
  source       = "./resources/scale_common/generate_keys"
  invoke_count = var.spectrum_scale_enabled ? 1 : 0
  tf_data_path = format("%s", local.tf_data_path)
}

module "check_cluster_status" {
  source              = "./resources/ibmcloud/null/remote_exec"
  cluster_host        = concat(module.management_host[*].primary_network_interface)
  cluster_user        = local.cluster_user
  cluster_private_key = module.login_ssh_key.private_key
  login_host          = module.login_fip.floating_ip_address
  login_user          = "root"
  login_private_key   = module.login_ssh_key.private_key
  command             = ["sleep 60; lshosts -w; lsid"]
  depends_on = [
    module.bastion_vsi,
    module.management_host,
    module.management_host_candidate,
    module.worker_vsi,
    module.custom_resolver
  ]
}

module "check_node_status" {
  source              = "./resources/ibmcloud/null/remote_exec"
  cluster_host        = concat(module.management_host[*].primary_network_interface, module.management_host_candidate[*].primary_network_interface)
  cluster_user        = local.cluster_user
  cluster_private_key = module.login_ssh_key.private_key
  login_host          = module.login_fip.floating_ip_address
  login_user          = "root"
  login_private_key   = module.login_ssh_key.private_key
  command             = ["lsf_daemons status"]
  depends_on = [
    module.bastion_vsi,
    module.management_host,
    module.management_host_candidate,
    module.check_cluster_status,
    module.worker_vsi,
    module.custom_resolver
  ]
}

// After completion of scale storage nodes, nodes need wait time to get in running state.
module "storage_nodes_wait" { # Setting up the variable time as 180s for the entire set of storage nodes, this approach is used to overcome the issue of ssh and nodes unreachable
  count         = (var.spectrum_scale_enabled && var.scale_storage_node_count > 0) ? 1 : 0
  source        = "./resources/scale_common/wait"
  wait_duration = var.TF_WAIT_DURATION
  depends_on    = [module.spectrum_scale_storage, module.custom_resolver]
}

// After completion of compute nodes, nodes need wait time to get in running state.
module "compute_nodes_wait" { # Setting up the variable time as 180s for the entire set of compute nodes, this approach is used to overcome the issue of ssh and nodes unreachable
  count         = (var.spectrum_scale_enabled && var.scale_storage_node_count > 0) ? 1 : 0
  source        = "./resources/scale_common/wait"
  wait_duration = var.TF_WAIT_DURATION
  depends_on    = [module.management_host, module.management_host_candidate, module.worker_vsi, module.custom_resolver]
}

// This module is used to clone ansible repo for scale.
module "prepare_spectrum_scale_ansible_repo" {
  count      = var.spectrum_scale_enabled ? 1 : 0
  source     = "./resources/scale_common/git_utils"
  branch     = "scale_cloud"
  tag        = null
  clone_path = local.scale_infra_repo_clone_path
}

module "invoke_storage_playbook" {
  count                        = (var.spectrum_scale_enabled && var.scale_storage_node_count > 0) ? 1 : 0
  source                       = "./resources/scale_common/ansible_storage_playbook"
  region                       = local.region_name
  stack_name                   = format("%s.%s", var.cluster_prefix, "storage")
  tf_data_path                 = local.tf_data_path
  tf_input_json_root_path      = local.tf_input_json_root_path == null ? abspath(path.cwd) : local.tf_input_json_root_path
  tf_input_json_file_name      = local.tf_input_json_file_name == null ? join(", ", fileset(abspath(path.cwd), "*.tfvars*")) : local.tf_input_json_file_name
  bastion_public_ip            = module.login_fip.floating_ip_address
  bastion_os_flavor            = data.ibm_is_image.stock_image.os
  bastion_ssh_private_key      = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  scale_infra_repo_clone_path  = local.scale_infra_repo_clone_path
  clone_complete               = var.spectrum_scale_enabled ? module.prepare_spectrum_scale_ansible_repo[0].clone_complete : false
  scale_version                = local.scale_version
  filesystem_mountpoint        = var.scale_storage_cluster_filesystem_mountpoint
  filesystem_block_size        = var.scale_filesystem_block_size
  storage_cluster_gui_username = var.scale_storage_cluster_gui_username
  storage_cluster_gui_password = var.scale_storage_cluster_gui_password
  cloud_platform               = local.cloud_platform
  avail_zones                  = jsonencode([var.zone])
  compute_instance_desc_map    = jsonencode([])
  compute_instance_desc_id     = jsonencode([])
  host                         = chomp(data.http.fetch_myip.response_body)
  storage_instances_by_id      = local.strg_vsi_ids_0_disks == null ? jsondecode([]) : jsonencode(local.strg_vsi_ids_0_disks)
  storage_instance_disk_map    = local.strg_vsi_ips_0_disks_dev_map == null ? jsondecode([]) : jsonencode(local.strg_vsi_ips_0_disks_dev_map)
  depends_on                   = [module.login_ssh_key, module.prepare_spectrum_scale_ansible_repo, module.storage_nodes_wait, module.login_vsi, module.spectrum_scale_storage]
}

module "invoke_compute_playbook" {
  count                         = (var.spectrum_scale_enabled && var.worker_node_min_count > 0) ? 1 : 0
  source                        = "./resources/scale_common/ansible_compute_playbook"
  region                        = local.region_name
  stack_name                    = format("%s.%s", var.cluster_prefix, "compute")
  tf_data_path                  = local.tf_data_path
  tf_input_json_root_path       = local.tf_input_json_root_path == null ? abspath(path.cwd) : local.tf_input_json_root_path
  tf_input_json_file_name       = local.tf_input_json_file_name == null ? join(", ", fileset(abspath(path.cwd), "*.tfvars*")) : local.tf_input_json_file_name
  bastion_public_ip             = module.login_fip.floating_ip_address
  bastion_os_flavor             = data.ibm_is_image.stock_image.os
  bastion_ssh_private_key       = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  scale_infra_repo_clone_path   = local.scale_infra_repo_clone_path
  clone_complete                = var.spectrum_scale_enabled ? module.prepare_spectrum_scale_ansible_repo[0].clone_complete : false
  scale_version                 = local.scale_version
  compute_filesystem_mountpoint = var.scale_compute_cluster_filesystem_mountpoint
  compute_cluster_gui_username  = var.scale_compute_cluster_gui_username
  compute_cluster_gui_password  = var.scale_compute_cluster_gui_password
  cloud_platform                = local.cloud_platform
  avail_zones                   = jsonencode([var.zone])
  compute_instances_by_id       = jsonencode(local.compute_vsi_ids_0_disks)
  host                          = chomp(data.http.fetch_myip.response_body)
  compute_instances_by_ip       = local.compute_vsi_by_ip == null ? jsonencode([]) : jsonencode(local.compute_vsi_by_ip)
  depends_on                    = [module.login_ssh_key, module.management_host, module.management_host_candidate, module.worker_vsi, module.compute_nodes_wait]
}

// This module is used to invoke remote mount
module "invoke_remote_mount" {
  count                       = var.spectrum_scale_enabled ? 1 : 0
  source                      = "./resources/scale_common/ansible_remote_mount_playbook"
  scale_infra_repo_clone_path = local.scale_infra_repo_clone_path
  cloud_platform              = local.cloud_platform
  tf_data_path                = local.tf_data_path
  bastion_public_ip           = module.login_fip.floating_ip_address
  bastion_os_flavor           = data.ibm_is_image.stock_image.os
  bastion_ssh_private_key     = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  total_compute_instances     = local.total_compute_instances
  total_storage_instances     = var.scale_storage_node_count
  host                        = chomp(data.http.fetch_myip.response_body)
  clone_complete              = var.spectrum_scale_enabled ? module.prepare_spectrum_scale_ansible_repo[0].clone_complete : false
  depends_on                  = [module.invoke_compute_playbook, module.invoke_storage_playbook, module.sg, module.login_sg]
}

module "permission_to_lsfadmin_for_mount_point" {
  count                   = var.spectrum_scale_enabled ? 1 : 0
  source                  = "./resources/scale_common/add_permission"
  bastion_ssh_private_key = var.spectrum_scale_enabled ? module.login_ssh_key.private_key_path : ""
  compute_instances_by_ip = local.compute_vsi_by_ip == null ? jsonencode([]) : jsonencode(local.compute_vsi_by_ip)
  login_ip                = module.login_fip.floating_ip_address
  scale_mount_point       = var.scale_compute_cluster_filesystem_mountpoint
  depends_on              = [module.invoke_remote_mount]
}

#########################################################################################################
# validation_script_executor Module
#
# Purpose: This module is included for testing purposes.
# It provides a conditional mechanism for executing remote scripts on cluster hosts.
# The execution is triggered if the script filenames listed in TF_VALIDATION_SCRIPT_FILES are provided.
#
# Usage:
# - When scripts are listed in TF_VALIDATION_SCRIPT_FILES, the corresponding scripts
#   will be executed on the cluster hosts using remote command execution.
# - The conditional nature ensures that scripts are executed only when necessary.
#   This can be useful for various validation or maintenance tasks.
#########################################################################################################

# module "validation_script_executor" {
#   source = "./resources/ibmcloud/null/remote_exec"
#   count  = var.TF_VALIDATION_SCRIPT_FILES != null && length(var.TF_VALIDATION_SCRIPT_FILES) > 0 ? 1 : 0

#   cluster_host        = concat(module.management_host[*].primary_network_interface)
#   cluster_user        = local.cluster_user
#   cluster_private_key = module.login_ssh_key.private_key
#   login_host          = module.login_fip.floating_ip_address
#   login_user          = "root"
#   login_private_key   = module.login_ssh_key.private_key

#   command = [
#     for script_name in var.TF_VALIDATION_SCRIPT_FILES :
#     file("${path.module}/examples/scripts/${script_name}")
#   ]
#   depends_on = [
#     module.bastion_vsi,
#     module.management_host,
#     module.management_host_candidate,
#     module.worker_vsi,
#     module.check_cluster_status,
#     module.check_node_status
#   ]
# }

# Module removes the public ssh key created by Schematics to access all nodes for both LSF and Scale deployment.
module "remove_ssh_key" {
  source                  = "./resources/scale_common/remove_ssh"
  bastion_ssh_private_key = module.login_ssh_key.private_key_path
  # compute_vsi_by_ip fetches the primary IP address of Management/Management_candidate/Worker nodes, when spectrum scale is set as true.
  compute_instances_by_ip = var.spectrum_scale_enabled ? jsonencode(local.compute_vsi_by_ip) : jsonencode(module.management_host[*].primary_network_interface)
  key_to_remove           = module.login_ssh_key.public_key
  login_ip                = module.login_fip.floating_ip_address
  storage_vsis_1A_by_ip   = var.spectrum_scale_enabled == true ? jsonencode(local.storage_vsis_1A_by_ip) : jsonencode([])
  host                    = chomp(data.http.fetch_myip.response_body)
  depends_on = [module.permission_to_lsfadmin_for_mount_point, module.invoke_remote_mount, module.check_cluster_status, module.
  check_node_status]
}


data "ibm_iam_auth_token" "token" {}

resource "null_resource" "delete_schematics_ingress_security_rule" { # This code executes to refresh the IAM token, so during the execution we would have the latest token updated of IAM cloud so we can destroy the security group rule through API calls
  count = var.spectrum_scale_enabled ? 1 : 0
  provisioner "local-exec" {
    environment = {
      REFRESH_TOKEN       = data.ibm_iam_auth_token.token.iam_refresh_token
      REGION              = local.region_name
      SECURITY_GROUP      = module.login_sg.sec_group_id
      SECURITY_GROUP_RULE = module.schematics_sg_tcp_rule.security_rule_id
    }
    command = <<EOT
          echo $SECURITY_GROUP
          echo $SECURITY_GROUP_RULE
          TOKEN=$(
            echo $(
              curl -X POST "https://iam.cloud.ibm.com/identity/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=refresh_token&refresh_token=$REFRESH_TOKEN" -u bx:bx
              ) | jq  -r .access_token
          )
          curl -X DELETE "https://$REGION.iaas.cloud.ibm.com/v1/security_groups/$SECURITY_GROUP/rules/$SECURITY_GROUP_RULE?version=2021-08-03&generation=2" -H "Authorization: $TOKEN"
        EOT
  }
  depends_on = [
    module.remove_ssh_key,
    module.schematics_sg_tcp_rule,
    module.check_cluster_status,
    module.check_node_status
  ]
}

