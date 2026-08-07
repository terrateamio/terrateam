/**
 * # Mozilla workgroup
 * Retrieve workgroup ACL lists associated with data and gcp access workgroups.
 *
 * Workgroup identifiers should be of the form:
 *
 * ```
 * workgroup:WORKGROUP_NAME[/SUBGROUP]
 * ```
 *
 * where `SUBGROUP` defaults to `default`. For example: `workgroup:app`, `workgroup:app/admin`.
 *
 * For subgroup queries across all workgroups, an additional identifier format:
 *
 * ```
 * subgroup:SUBGROUP
 * ```
 *
 * is supported, which will return all workgroups that contain a particular subgroup.
 *
 * This module is cloned from https://github.com/mozilla-services/cloudops-infra-terraform-modules/tree/master/data-workgroup.
 *
 */

data "terraform_remote_state" "workgroups" {
  backend = "gcs"

  config = {
    bucket = var.terraform_remote_state_bucket
    prefix = var.terraform_remote_state_prefix
  }
}

locals {
  workgroups = data.terraform_remote_state.workgroups.outputs.workgroups
  # there isn't a good way of dynamically propagating outputs, so this wrapper
  # module will need to be updated in the event more convenience outputs are
  # added e.g. storage_read_acls
  # the alternative would be to only expose members via this interface, which
  # is always authoritative, and leave it up to the calling module to
  # restructure the output as needed
  outputs = var.workgroup_outputs

  # convert all workgroup identifiers into [workgroup, subgroup] format
  workgroup_ids = [for workgroup in var.ids :
    workgroup if length(regexall("^workgroup:", workgroup)) > 0
  ]

  normalized_workgroups = [for workgroup in local.workgroup_ids :
    slice(compact(concat(split("/", trimprefix(workgroup, "workgroup:")), ["default"])), 0, 2)
  ]

  # convert all subgroup identifiers into ["*", subgroup] format
  subgroup_ids = [for subgroup in var.ids :
    subgroup if length(regexall("^subgroup:", subgroup)) > 0
  ]

  normalized_subgroups = [for subgroup in local.subgroup_ids :
    ["*", trimprefix(subgroup, "subgroup:")]
  ]

  # combine the two reference types
  normalized_ids = concat(local.normalized_workgroups, local.normalized_subgroups)

  # expand * if necessary to create a full list of workgroups
  expanded_workgroups = distinct(concat([], [
    for workgroup in local.normalized_ids : workgroup[0] == "*" ?
    [for key in keys(local.workgroups) : [key, workgroup[1]]] : [workgroup]
  ]...))

  # bespoke error checking designed to fail when an unknown subgroup is
  # specified, to match behavior when an unknown workgroup is specified
  subgroups_all = distinct(flatten([
    for workgroup in local.workgroups : [
      for output_type, output_value in workgroup : keys(output_value) if contains(local.outputs, output_type)
    ]
  ]))

  subgroups_test = [for subgroup in local.normalized_subgroups : index(local.subgroups_all, subgroup[1])]

  access = { for k in local.outputs : k => distinct(flatten(concat(
    [for workgroup in local.expanded_workgroups : lookup(lookup(local.workgroups[workgroup[0]], k, {}), workgroup[1], [])],
  ))) }


  # Compute bigquery dataset ACLs from service_accounts and google_groups
  bigquery_acl_entries = concat(
    [for sa in lookup(local.access, "service_accounts", []) : { user_by_email = sa }],
    [for group in lookup(local.access, "google_groups", []) : { group_by_email = group }],
  )

  bigquery_acls = { for output, role in var.roles :
    "${output}_acls" => toset([
      for entry in local.bigquery_acl_entries :
      merge(entry, { role = role })
    ])
  }
}
