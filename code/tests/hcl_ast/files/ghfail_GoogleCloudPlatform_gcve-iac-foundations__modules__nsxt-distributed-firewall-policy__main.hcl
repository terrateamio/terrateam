/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  ip_address_regex       = "(\\b25[0-5]|\\b2[0-4][0-9]|\\b[01]?[0-9][0-9]?)(\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}"
  ip_address_range_regex = "${local.ip_address_regex}\\-${local.ip_address_regex}"
  destination_groups = toset(
    flatten(
      [
        for each_rule in(var.rules != null ? var.rules : []) :
        [
          for each_dg in each_rule["destination_groups"] : each_dg
          if try(cidrnetmask(each_dg), null) == null
          && try(regex(local.ip_address_regex, each_dg), null) == null
          && try(regex(local.ip_address_range_regex, each_dg), null) == null
        ]
      ]
    )
  )
  source_groups = toset(
    flatten(
      [
        for each_rule in(var.rules != null ? var.rules : []) :
        [
          for each_sg in each_rule["source_groups"] : each_sg
          if try(cidrnetmask(each_sg), null) == null
          && try(regex(local.ip_address_regex, each_sg), null) == null
          && try(regex(local.ip_address_range_regex, each_sg), null) == null
        ]
      ]
    )
  )
  rules = [
    for each_rule in(var.rules != null ? var.rules : []) :
    merge(
      each_rule,
      { destination_groups = [
        for each_dg in each_rule["destination_groups"] :
        contains(local.destination_groups, each_dg) ? data.nsxt_policy_group.policy_groups[each_dg].path :
        each_dg
        ]
      },
      { source_groups = [
        for each_sg in each_rule["source_groups"] :
        contains(local.source_groups, each_sg) ? data.nsxt_policy_group.policy_groups[each_sg].path :
        each_sg
        ]
      }
    )
  ]
}

# Lookup existing policy group
data "nsxt_policy_group" "policy_groups" {
  for_each     = setunion(local.destination_groups, local.source_groups)
  display_name = each.key
}

data "nsxt_policy_service" "this" {
  depends_on = [nsxt_policy_service.this]

  # Lookup the NSX-T path for every service listed in all of the rules
  for_each     = toset(flatten(local.rules.*.services))
  display_name = each.value
}

resource "nsxt_policy_security_policy" "this" {
  depends_on      = [data.nsxt_policy_service.this]
  display_name    = var.display_name
  description     = var.resource_description
  category        = var.category
  locked          = var.locked
  stateful        = var.stateful
  tcp_strict      = var.tcp_strict
  scope           = var.scope
  sequence_number = var.sequence_number
  comments        = var.comments
  domain          = var.domain

  dynamic "rule" {

    for_each = local.rules
    content {
      display_name          = rule.value.display_name
      description           = rule.value.description
      destination_groups    = rule.value.destination_groups
      destinations_excluded = rule.value.destinations_excluded
      source_groups         = rule.value.source_groups
      sources_excluded      = rule.value.sources_excluded
      disabled              = rule.value.disabled
      action                = upper(rule.value.action)
      direction             = upper(rule.value.direction)
      logged                = rule.value.logged
      services              = [for s in rule.value.services : data.nsxt_policy_service.this[s].path]

      dynamic "tag" {
        for_each = coalesce(rule.value.tags, {})
        content {
          tag   = tag.key
          scope = tag.value
        }
      }
    }
  }

  dynamic "tag" {
    for_each = coalesce(var.tags, {})
    content {
      tag   = tag.key
      scope = tag.value
    }
  }
}

resource "nsxt_policy_service" "this" {
  for_each     = try(var.custom_l4_services, {})
  description  = var.resource_description
  display_name = each.key

  l4_port_set_entry {
    display_name      = each.key
    description       = try(each.value.description, null)
    protocol          = each.value.protocol
    destination_ports = each.value.destination_ports
    source_ports      = try(each.value.source_ports, null)
  }

  dynamic "tag" {
    for_each = coalesce(each.value.tags, {})
    content {
      scope = tag.key
      tag   = tag.value
    }
  }
}

