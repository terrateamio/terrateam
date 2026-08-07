# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  #--------------------------------------------------------------------------------------------
  #-- Enclosing compartments policies
  #--------------------------------------------------------------------------------------------

  #-- Read grants on enclosing compartment.
  read_grants_on_enclosing_cmp_map = {
    for k, values in local.cmp_name_to_cislz_tag_map : k => (contains(split(",", values["cmp-type"]), "enclosing") && values["read-group"] != null) ?
    values["ocid"] != var.tenancy_ocid ?
    ["allow group ${values["read-group"]} to read all-resources in compartment ${values["name"]}"] :

    ["allow group ${values["read-group"]} to read all-resources in tenancy"] :
    []
  }

  #-- IAM admin grants on enclosing compartment.
  iam_admin_grants_on_enclosing_cmp_map = {
    for k, values in local.cmp_name_to_cislz_tag_map : k => (contains(split(",", values["cmp-type"]), "enclosing") && values["iam-group"] != null) ?
    values["ocid"] != var.tenancy_ocid ?
    ["allow group ${values["iam-group"]} to manage policies in compartment ${values["name"]}",
    "allow group ${values["iam-group"]} to manage compartments in compartment ${values["name"]}"] :

    ["allow group ${values["iam-group"]} to manage policies in tenancy",
    "allow group ${values["iam-group"]} to manage compartments in tenancy"] :
    []
  }

  #-- Security admin grants on enclosing compartment.
  security_admin_grants_on_enclosing_cmp_map = {
    for k, values in local.cmp_name_to_cislz_tag_map : k => (contains(split(",", values["cmp-type"]), "enclosing") && values["sec-group"] != null) ?
    values["ocid"] != var.tenancy_ocid ?
    ["allow group ${values["sec-group"]} to manage tag-namespaces in compartment ${values["name"]}",
      "allow group ${values["sec-group"]} to manage tag-defaults in compartment ${values["name"]}",
      "allow group ${values["sec-group"]} to manage repos in compartment ${values["name"]}",
      "allow group ${values["sec-group"]} to read audit-events in compartment ${values["name"]}",
      "allow group ${values["sec-group"]} to read app-catalog-listing in compartment ${values["name"]}",
      "allow group ${values["sec-group"]} to read instance-images in compartment ${values["name"]}",
    "allow group ${values["sec-group"]} to inspect buckets in compartment ${values["name"]}"] :

    ["allow group ${values["sec-group"]} to manage tag-namespaces in tenancy",
      "allow group ${values["sec-group"]} to manage tag-defaults in tenancy",
      "allow group ${values["sec-group"]} to manage repos in tenancy",
      "allow group ${values["sec-group"]} to read audit-events in tenancy",
      "allow group ${values["sec-group"]} to read app-catalog-listing in tenancy",
      "allow group ${values["sec-group"]} to read instance-images in tenancy",
    "allow group ${values["sec-group"]} to inspect buckets in tenancy"] :
    []
  }

  #-- Application admin grants on enclosing compartment.
  application_admin_grants_on_enclosing_cmp_map = {
    for k, values in local.cmp_name_to_cislz_tag_map : k => (contains(split(",", values["cmp-type"]), "enclosing") && values["app-group"] != null) ?
    values["ocid"] != var.tenancy_ocid ?
    ["allow group ${values["app-group"]} to read app-catalog-listing in compartment ${values["name"]}",
      "allow group ${values["app-group"]} to read instance-images in compartment ${values["name"]}",
    "allow group ${values["app-group"]} to read repos in compartment ${values["name"]}"] :

    ["allow group ${values["app-group"]} to read app-catalog-listing in tenancy",
      "allow group ${values["app-group"]} to read instance-images in tenancy",
    "allow group ${values["app-group"]} to read repos in tenancy"] :
    []
  }

  #-- Policies for compartments marked as enclosing compartments (values["cmp-type"] == "enclosing").
  enclosing_cmps_policies = {
    for k, values in local.cmp_name_to_cislz_tag_map :
    (upper("${k}-enclosing-policy")) => {
      name           = length(regexall("^${local.policy_name_prefix}", values["name"])) > 0 ? (length(split(",", values["cmp-type"])) > 1 ? "${values["name"]}-enclosing${local.policy_name_suffix}" : "${values["name"]}${local.policy_name_suffix}") : (length(split(",", values["cmp-type"])) > 1 ? "${local.policy_name_prefix}${values["name"]}-enclosing${local.policy_name_suffix}" : "${local.policy_name_prefix}${values["name"]}${local.policy_name_suffix}")
      compartment_id = values.ocid
      description    = "Core Landing Zone policy for enclosing compartment."
      defined_tags   = var.policies_configuration.defined_tags
      freeform_tags  = var.policies_configuration.freeform_tags
      statements = concat(local.read_grants_on_enclosing_cmp_map[k], local.iam_admin_grants_on_enclosing_cmp_map[k],
      local.security_admin_grants_on_enclosing_cmp_map[k], local.application_admin_grants_on_enclosing_cmp_map[k])
    }
    if contains(split(",", values["cmp-type"]), "enclosing")
  }
}

/* resource "random_string" "this" {
  length  = 5
  special = false
  upper   = false
} */