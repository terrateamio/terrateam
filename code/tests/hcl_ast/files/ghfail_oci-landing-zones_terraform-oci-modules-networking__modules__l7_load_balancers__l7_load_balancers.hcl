# ####################################################################################################### #
# Copyright (c) 2023 Oracle and/or its affiliates,  All rights reserved.                                  #
# Licensed under the Universal Permissive License v 1.0 as shown at https: //oss.oracle.com/licenses/upl. #
# Author: Cosmin Tudor                                                                                    #
# Author email: cosmin.tudor@oracle.com                                                                   #
# Last Modified: Wed Nov 15 2023                                                                          #
# Modified by: Cosmin Tudor, email: cosmin.tudor@oracle.com                                               #
# ####################################################################################################### #

locals {

  one_dimension_processed_l7_load_balancers = var.l7_load_balancers_configuration.l7_load_balancers
  provisioned_oci_core_public_ips           = var.l7_load_balancers_configuration.dependencies.public_ips
  provisioned_subnets                       = var.l7_load_balancers_configuration.dependencies.subnets
  provisioned_network_security_groups       = var.l7_load_balancers_configuration.dependencies.network_security_groups


  provisioned_l7_lbs = {
    for l7lb_key, l7lb_value in oci_load_balancer_load_balancer.these : l7lb_key => {
      compartment_id             = l7lb_value.compartment_id
      defined_tags               = l7lb_value.defined_tags
      display_name               = l7lb_value.display_name
      freeform_tags              = l7lb_value.freeform_tags
      ip_mode                    = l7lb_value.ip_mode
      is_private                 = l7lb_value.is_private
      network_security_group_ids = l7lb_value.network_security_group_ids
      id                         = l7lb_value.id

      network_security_groups = {
        for nsg in flatten(l7lb_value.network_security_group_ids != null ? [
          for nsg_id in l7lb_value.network_security_group_ids : contains(local.provisioned_network_security_groups != null ? [
            for nsg_key, nsg_value in local.provisioned_network_security_groups : nsg_value.id
            ] : [],
            nsg_id) ? local.provisioned_network_security_groups != null ? [
            for nsg_key, nsg_value in local.provisioned_network_security_groups : {
              display_name = nsg_value.display_name
              nsg_key      = nsg_key
              nsg_id       = nsg_id
            } if nsg_value.id == nsg_id] : [
            {
              display_name = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              nsg_key      = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              nsg_id       = nsg_id
            }
            ] : [
            {
              display_name = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              nsg_key      = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              nsg_id       = nsg_id
            }
          ]
          ] : []) : nsg.nsg_id => {
          display_name = nsg.display_name
          nsg_key      = nsg.nsg_key
          nsg_id       = nsg.nsg_id
        }
      }

      reserved_ips = l7lb_value.reserved_ips
      #      reserved_public_ips = {
      #        for rpip in flatten(l7lb_value.reserved_ips != null ? [
      #          for rpip_id in l7lb_value.reserved_ips : contains([
      #            for rpip_id_key, rpip_id_value in local.provisioned_oci_core_public_ips : rpip_id_value.id
      #            ],
      #
      #            rpip_id) ? local.provisioned_oci_core_public_ips != null ? [
      #            for rpip_id_key, rpip_id_value in local.provisioned_oci_core_public_ips : {
      #              display_name = rpip_id_value.display_name
      #              rpip_id_key  = rpip_id_key
      #              rpip_id      = rpip_id
      #            } if rpip_id_value.id == rpip_id] : [
      #            {
      #              display_name = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
      #              rpip_id_key  = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
      #              rpip_id      = rpip_id
      #            }
      #            ] : [
      #            {
      #              display_name = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
      #              rpip_id_key  = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
      #              rpip_id      = rpip_id
      #            }
      #          ]
      #          ] : []) : rpip.rpip_id => {
      #          display_name = rpip.display_name
      #          rpip_id_key  = rpip.rpip_id_key
      #          rpip_id      = rpip.rpip_id
      #        }
      #      }
      shape         = l7lb_value.shape
      shape_details = l7lb_value.shape_details
      subnet_ids    = l7lb_value.subnet_ids
      subnets = {
        for subnet in flatten(l7lb_value.subnet_ids != null ? [
          for subnet_id in l7lb_value.subnet_ids : contains(local.provisioned_subnets != null ? [
            for subnet_key, subnet_value in local.provisioned_subnets : subnet_value.id
            ] : [],
            subnet_id) ? local.provisioned_subnets != null ? [
            for subnet_key, subnet_value in local.provisioned_subnets : {
              display_name = subnet_value.display_name
              subnet_key   = subnet_key
              subnet_id    = subnet_id
              vcn_key      = subnet_value.vcn_key
              vcn_name     = subnet_value.vcn_name
              vcn_id       = subnet_value.vcn_id
            } if subnet_value.id == subnet_id] : [
            {
              display_name = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              subnet_key   = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              subnet_id    = subnet_id
              vcn_key      = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              vcn_name     = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              vcn_id       = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
            }
          ] :
          [
            {
              display_name = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              subnet_key   = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              subnet_id    = subnet_id
              vcn_key      = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              vcn_name     = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
              vcn_id       = "NOT DETERMINED AS NOT CREATED BY THIS AUTOMATION"
            }
          ]
          ] : []) : subnet.subnet_id => {
          display_name = subnet.display_name
          subnet_key   = subnet.subnet_key
          subnet_id    = subnet.subnet_id
          vcn_key      = subnet.vcn_key
          vcn_name     = subnet.vcn_name
          vcn_id       = subnet.vcn_id
        }
      }
      network_configuration_category = local.one_dimension_processed_l7_load_balancers[l7lb_key].network_configuration_category
      security_attributes            = l7lb_value.security_attributes
    }
  }
}

resource "oci_load_balancer_load_balancer" "these" {
  for_each = local.one_dimension_processed_l7_load_balancers != null ? local.one_dimension_processed_l7_load_balancers : {}
  #Required
  compartment_id = each.value.compartment_id != null ? (length(regexall("^ocid1.*$", each.value.compartment_id)) > 0 ? each.value.compartment_id : var.compartments_dependency[each.value.compartment_id].id) : null
  display_name   = each.value.display_name
  shape          = each.value.shape
  subnet_ids     = [for subnet_id in each.value.subnet_ids : length(regexall("^ocid1.*$", subnet_id)) > 0 ? subnet_id : var.network_dependency.subnets[subnet_id].id]

  #Optional
  defined_tags               = each.value.defined_tags
  freeform_tags              = merge(local.cislz_module_tag, each.value.freeform_tags)
  ip_mode                    = each.value.ip_mode
  is_private                 = each.value.is_private
  network_security_group_ids = each.value.network_security_group_ids
  dynamic "reserved_ips" {
    for_each = each.value.reserved_ips_ids
    content {
      id = reserved_ips.value
    }
  }
  shape_details {
    maximum_bandwidth_in_mbps = each.value.shape_details.maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = each.value.shape_details.minimum_bandwidth_in_mbps
  }

  security_attributes = merge({}, [
    for v in try(each.value.security.zpr_attributes, []) : {
      "${v.namespace}.${v.attr_name}.value" : v.attr_value
      "${v.namespace}.${v.attr_name}.mode" : v.mode
    }
  ]...)


}
