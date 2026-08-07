# Copyright (c) 2024, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_bastion_bastion" "these" {
  for_each = var.bastions_configuration != null ? var.bastions_configuration["bastions"] : {}
  lifecycle {
    ## Check 1: Check if the value of the session time to live.
    precondition {
      condition     = each.value.max_session_ttl_in_seconds != null ? each.value.max_session_ttl_in_seconds < 1800 || each.value.max_session_ttl_in_seconds > 10800 ? false : true : true
      error_message = "VALIDATION FAILURE in bastion \"${each.key}\": the session time to live must be between 1800s(30min) and 10800s(3h). Please change the \"max_session_ttl_in_seconds\" attribute value."
    }
    ## Check 2: Check if cidr_block_allow_list or var.bastions_configuration.default_cidr_block_allow_list is set
    precondition {
      condition     = each.value.cidr_block_allow_list != null || var.bastions_configuration.default_cidr_block_allow_list != null
      error_message = "VALIDATION FAILURE in bastion \"${each.key}\": You must provide at least one CIDR block either in \"cidr_block_allow_list\" or \"default_cidr_block_allow_list\". "
    }
    ## Check 3: Check if cidr_block_allow_list or var.bastions_configuration.default_cidr_block_allow_list is 0.0.0.0\0
    precondition {
      condition     = var.bastions_configuration.enable_cidr_check ? (each.value.cidr_block_allow_list != null ? (contains(each.value.cidr_block_allow_list, "0.0.0.0/0") ? false : true) : var.bastions_configuration.default_cidr_block_allow_list != null(contains(var.bastions_configuration.default_cidr_block_allow_list, "0.0.0.0/0") ? false : true)) : true
      error_message = "VALIDATION FAILURE in bastion \"${each.key}\": \"cidr_block_allow_list\" or \"default_cidr_block_allow_list\" must not be \"0.0.0.0/0\". Either change their values or disable this check by setting \"enable_cidr_check\" attribute of \"bastions_configuration\" to false."
    }
  }
  bastion_type                 = upper(each.value.bastion_type)
  compartment_id               = each.value.compartment_id != null ? (length(regexall("^ocid1.*$", each.value.compartment_id)) > 0 ? each.value.compartment_id : var.compartments_dependency[each.value.compartment_id].id) : (length(regexall("^ocid1.*$", var.bastions_configuration.default_compartment_id)) > 0 ? var.bastions_configuration.default_compartment_id : var.compartments_dependency[var.bastions_configuration.default_compartment_id].id)
  target_subnet_id             = each.value.subnet_id != null ? (length(regexall("^ocid1.*$", each.value.subnet_id)) > 0 ? each.value.subnet_id : var.network_dependency["subnets"][each.value.subnet_id].id) : (length(regexall("^ocid1.*$", var.bastions_configuration.default_subnet_id)) > 0 ? var.bastions_configuration.default_subnet_id : var.network_dependency["subnets"][var.bastions_configuration.default_subnet_id].id)
  defined_tags                 = each.value.defined_tags != null ? each.value.defined_tags : var.bastions_configuration.default_defined_tags
  freeform_tags                = merge(local.cislz_module_tag, each.value.freeform_tags != null ? each.value.freeform_tags : var.bastions_configuration.default_freeform_tags)
  client_cidr_block_allow_list = each.value.cidr_block_allow_list != null ? each.value.cidr_block_allow_list : var.bastions_configuration.default_cidr_block_allow_list
  dns_proxy_status             = each.value.enable_dns_proxy ? "ENABLED" : "DISABLED"
  max_session_ttl_in_seconds   = each.value.max_session_ttl_in_seconds
  name                         = each.value.name
}