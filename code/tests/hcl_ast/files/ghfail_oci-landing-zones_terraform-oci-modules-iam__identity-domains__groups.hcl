# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Existing identity domains
data "oci_identity_domain" "grp_domain" {
  for_each = (var.identity_domain_groups_configuration != null) ? (var.identity_domain_groups_configuration["groups"] != null ? var.identity_domain_groups_configuration["groups"] : {}) : {}
  domain_id = each.value.identity_domain_id != null ? length(regexall("^ocid1.*$", each.value.identity_domain_id)) > 0 ? each.value.identity_domain_id : (contains(keys(var.identity_domains_dependency), each.value.identity_domain_id) ? var.identity_domains_dependency[each.value.identity_domain_id].id : "__VOID__") : length(regexall("^ocid1.*$", var.identity_domain_groups_configuration.default_identity_domain_id)) > 0 ? var.identity_domain_groups_configuration.default_identity_domain_id : (contains(keys(var.identity_domains_dependency), var.identity_domain_groups_configuration.default_identity_domain_id) ? var.identity_domains_dependency[var.identity_domain_groups_configuration.default_identity_domain_id].id : "__VOID__")
}

locals {
  # Map of identity domains with all requested members
  identity_domains_members = { for k, g in try(var.identity_domain_groups_configuration.groups, {}) :
    coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id)
  => g.members... }
  # Map of identity domains with all requested members (flattened, dupes removed)
  identity_domains_members_flattened = { for k, g in local.identity_domains_members : k => toset(flatten(g)) }
  # Map of identity domains with their respective endpoint URLs and requested members
  identity_domains = merge(
    { for k, g in try(var.identity_domain_groups_configuration.groups, {}) :
      coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id)
      => {
        "url" : oci_identity_domain.these[coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id)].url,
      "members" : local.identity_domains_members_flattened[coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id)] }...
      if length(g.members) > 0 &&
      # use identity domain created in same session when the identity domain id is not ocid, and is not a depdency key
      (length(regexall("^ocid1.*$", coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id))) == 0 &&
        !contains(keys(coalesce(var.identity_domains_dependency, {})), coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id))
    ) }
    ,
    { for k, g in try(var.identity_domain_groups_configuration.groups, {}) :
      coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id)
      => {
        "url" : data.oci_identity_domain.grp_domain[k].url,
      "members" : local.identity_domains_members_flattened[coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id)] }...
      if length(g.members) > 0 && (
        # use existing identity domain when the identity domain id is an ocid or dependency key
        length(regexall("^ocid1.*$", coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id))) > 0 ||
        contains(keys(coalesce(var.identity_domains_dependency, {})), coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id))
  ) })
}


# Users lookup. Used to retrieve the user id attribute for requested members. The user id is used when granting group membership (see dynamic "members" block in resource "oci_identity_domains_group" "these").
data "oci_identity_domains_users" "these" {
  for_each      = local.identity_domains
  idcs_endpoint = each.value[0].url
  user_filter   = "active eq true ${length(each.value[0].members) > 0 ? "and (userName eq \"${join("\" or userName eq \"", each.value[0].members)}\")" : ""}"
  attributes    = "user_name,id"
}

locals {
  # Map of usernames with their respective retrieved user ids. The user id is used when granting group membership (see dynamic "members" block in resource "oci_identity_domains_group" "these).
  users = { for k, g in try(var.identity_domain_groups_configuration.groups, {}) : k => { for u in data.oci_identity_domains_users.these[coalesce(g.identity_domain_id, var.identity_domain_groups_configuration.default_identity_domain_id)].users : u.user_name => u.id... } if length(g.members) > 0 }
}

resource "oci_identity_domains_group" "these" {
  for_each = var.identity_domain_groups_configuration != null ? (try(var.identity_domain_groups_configuration.ignore_external_membership_updates, true) == true ? var.identity_domain_groups_configuration.groups : {}) : {}
  lifecycle {
    ignore_changes = all
    precondition {
      condition     = length(each.value.members) > 0 ? length(setsubtract(toset(each.value.members), toset([for m in each.value.members : m if contains(keys(local.users[each.key]), m)]))) == 0 : true
      error_message = length(each.value.members) > 0 ? "VALIDATION FAILURE: following provided usernames in \"members\" attribute of group \"${each.key}\" do not exist or are not active\": ${join(", ", setsubtract(toset(each.value.members), toset([for m in each.value.members : m if contains(keys(local.users[each.key]), m)])))}. Please either correct their spelling or activate them." : ""
    }
  }
  attribute_sets = ["all"]
  idcs_endpoint = each.value.identity_domain_id != null ? (
    contains(keys(oci_identity_domain.these), each.value.identity_domain_id) ? oci_identity_domain.these[each.value.identity_domain_id].url : (
    data.oci_identity_domain.grp_domain[each.key].url)
    ) : (
    contains(keys(oci_identity_domain.these), var.identity_domain_groups_configuration.default_identity_domain_id) ? oci_identity_domain.these[var.identity_domain_groups_configuration.default_identity_domain_id].url : (
    data.oci_identity_domain.grp_domain[each.key].url)
  )
  display_name = each.value.name
  schemas      = ["urn:ietf:params:scim:schemas:core:2.0:Group", "urn:ietf:params:scim:schemas:oracle:idcs:extension:requestable:Group", "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags", "urn:ietf:params:scim:schemas:oracle:idcs:extension:group:Group"]
  urnietfparamsscimschemasoracleidcsextensiongroup_group {
    creation_mechanism = "api"
    description        = each.value.description
  }
  dynamic "members" {
    for_each = length(each.value.members) > 0 ? each.value.members : []
    iterator = member
    content {
      type  = "User"
      value = local.users[each.key][member.value][0]
    }
  }
  urnietfparamsscimschemasoracleidcsextension_oci_tags {
    dynamic "defined_tags" {
      for_each = each.value.defined_tags != null ? each.value.defined_tags : (var.identity_domain_groups_configuration.default_defined_tags != null ? var.identity_domain_groups_configuration.default_defined_tags : {})
      content {
        key       = split(".", defined_tags["key"])[1]
        namespace = split(".", defined_tags["key"])[0]
        value     = trimspace(defined_tags["value"])
      }
    }
    dynamic "freeform_tags" {
      for_each = each.value.freeform_tags != null ? merge(local.cislz_module_tag, each.value.freeform_tags) : (var.identity_domain_groups_configuration.default_freeform_tags != null ? merge(local.cislz_module_tag, var.identity_domain_groups_configuration.default_freeform_tags) : local.cislz_module_tag)
      content {
        key   = freeform_tags["key"]
        value = trimspace(freeform_tags["value"])
      }
    }
  }
  urnietfparamsscimschemasoracleidcsextensionrequestable_group {
    requestable = each.value.requestable
  }
}

resource "oci_identity_domains_group" "these_with_external_membership_updates" {
  for_each = var.identity_domain_groups_configuration != null ? (try(var.identity_domain_groups_configuration.ignore_external_membership_updates, true) == false ? var.identity_domain_groups_configuration.groups : {}) : {}
  lifecycle {
    precondition {
      condition     = length(each.value.members) > 0 ? length(setsubtract(toset(each.value.members), toset([for m in each.value.members : m if contains(keys(local.users[each.key]), m)]))) == 0 : true
      error_message = length(each.value.members) > 0 ? "VALIDATION FAILURE: following provided usernames in \"members\" attribute of group \"${each.key}\" do not exist or are not active\": ${join(", ", setsubtract(toset(each.value.members), toset([for m in each.value.members : m if contains(keys(local.users[each.key]), m)])))}. Please either correct their spelling or activate them." : ""
    }
  }
  attribute_sets = ["all"]
  idcs_endpoint = each.value.identity_domain_id != null ? (
    contains(keys(oci_identity_domain.these), each.value.identity_domain_id) ? oci_identity_domain.these[each.value.identity_domain_id].url : (
    data.oci_identity_domain.grp_domain[each.key].url)
    ) : (
    contains(keys(oci_identity_domain.these), var.identity_domain_groups_configuration.default_identity_domain_id) ? oci_identity_domain.these[var.identity_domain_groups_configuration.default_identity_domain_id].url : (
    data.oci_identity_domain.grp_domain[each.key].url)
  )
  display_name = each.value.name
  schemas      = ["urn:ietf:params:scim:schemas:core:2.0:Group", "urn:ietf:params:scim:schemas:oracle:idcs:extension:requestable:Group", "urn:ietf:params:scim:schemas:oracle:idcs:extension:OCITags", "urn:ietf:params:scim:schemas:oracle:idcs:extension:group:Group"]
  urnietfparamsscimschemasoracleidcsextensiongroup_group {
    creation_mechanism = "api"
    description        = each.value.description
  }
  dynamic "members" {
    for_each = length(each.value.members) > 0 ? each.value.members : []
    iterator = member
    content {
      type  = "User"
      value = local.users[each.key][member.value][0]
    }
  }
  urnietfparamsscimschemasoracleidcsextension_oci_tags {
    dynamic "defined_tags" {
      for_each = each.value.defined_tags != null ? each.value.defined_tags : (var.identity_domain_groups_configuration.default_defined_tags != null ? var.identity_domain_groups_configuration.default_defined_tags : {})
      content {
        key       = split(".", defined_tags["key"])[1]
        namespace = split(".", defined_tags["key"])[0]
        value     = trimspace(defined_tags["value"])
      }
    }
    dynamic "freeform_tags" {
      for_each = each.value.freeform_tags != null ? merge(local.cislz_module_tag, each.value.freeform_tags) : (var.identity_domain_groups_configuration.default_freeform_tags != null ? merge(local.cislz_module_tag, var.identity_domain_groups_configuration.default_freeform_tags) : local.cislz_module_tag)
      content {
        key   = freeform_tags["key"]
        value = trimspace(freeform_tags["value"])
      }
    }
  }
  urnietfparamsscimschemasoracleidcsextensionrequestable_group {
    requestable = each.value.requestable
  }
}
