# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE ROUTE53 ZONES AND RECORDS
#
# This module creates one or multiple Route53 zones with associated records
# and a delegation set.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------
# Prepare locals to keep the code cleaner
# ------------------------------------------------------------------------------

locals {
  zones                        = var.name == null ? [] : try(tolist(var.name), [tostring(var.name)], [])
  skip_zone_creation           = length(local.zones) == 0
  run_in_vpc                   = length(var.vpc_ids) > 0
  skip_delegation_set_creation = !var.module_enabled || local.skip_zone_creation || local.run_in_vpc ? true : var.skip_delegation_set_creation

  delegation_set_id = var.delegation_set_id != null ? var.delegation_set_id : try(
    aws_route53_delegation_set.delegation_set[0].id, null
  )
}

# ------------------------------------------------------------------------------
# Create a delegation set to share the same nameservers among multiple zones
# ------------------------------------------------------------------------------

resource "aws_route53_delegation_set" "delegation_set" {
  count = local.skip_delegation_set_creation ? 0 : 1

  reference_name = var.reference_name

  depends_on = [var.module_depends_on]
}

# ------------------------------------------------------------------------------
# Create the zones
# ------------------------------------------------------------------------------

resource "aws_route53_zone" "zone" {
  for_each = var.module_enabled ? toset(local.zones) : []

  name              = each.value
  comment           = var.comment
  force_destroy     = var.force_destroy
  delegation_set_id = local.delegation_set_id

  dynamic "vpc" {
    for_each = { for id in var.vpc_ids : id => id }

    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(
    { Name = each.value },
    var.tags
  )

  depends_on = [var.module_depends_on]
}

# ------------------------------------------------------------------------------
# Prepare the records
# ------------------------------------------------------------------------------

locals {
  records_expanded = {
    for i, record in var.records : join("-", compact([
      lower(record.type),
      try(lower(record.set_identifier), ""),
      try(lower(record.failover), ""),
      try(lower(record.name), ""),
      ])) => {
      type = record.type
      name = try(record.name, "")
      ttl  = try(record.ttl, null)
      alias = {
        name                   = try(record.alias.name, null)
        zone_id                = try(record.alias.zone_id, null)
        evaluate_target_health = try(record.alias.evaluate_target_health, null)
      }
      allow_overwrite = try(record.allow_overwrite, var.allow_overwrite)
      health_check_id = try(record.health_check_id, null)
      idx             = i
      set_identifier  = try(record.set_identifier, null)
      weight          = try(record.weight, null)
      failover        = try(record.failover, null)
    }
  }

  records_by_name = {
    for product in setproduct(local.zones, keys(local.records_expanded)) : "${product[1]}-${product[0]}" => {
      zone_id         = try(aws_route53_zone.zone[product[0]].id, null)
      type            = local.records_expanded[product[1]].type
      name            = local.records_expanded[product[1]].name
      ttl             = local.records_expanded[product[1]].ttl
      alias           = local.records_expanded[product[1]].alias
      allow_overwrite = local.records_expanded[product[1]].allow_overwrite
      health_check_id = local.records_expanded[product[1]].health_check_id
      idx             = local.records_expanded[product[1]].idx
      set_identifier  = local.records_expanded[product[1]].set_identifier
      weight          = local.records_expanded[product[1]].weight
      failover        = local.records_expanded[product[1]].failover
    }
  }

  records_by_zone_id = {
    for id, record in local.records_expanded : id => {
      zone_id         = var.zone_id
      type            = record.type
      name            = record.name
      ttl             = record.ttl
      alias           = record.alias
      allow_overwrite = record.allow_overwrite
      health_check_id = record.health_check_id
      idx             = record.idx
      set_identifier  = record.set_identifier
      weight          = record.weight
      failover        = record.failover
    }
  }

  records = local.skip_zone_creation ? local.records_by_zone_id : local.records_by_name
}

# ------------------------------------------------------------------------------
# Attach the records to our created zone(s)
# ------------------------------------------------------------------------------

resource "aws_route53_record" "record" {
  for_each = var.module_enabled ? local.records : {}

  zone_id         = each.value.zone_id
  type            = each.value.type
  name            = each.value.name
  allow_overwrite = each.value.allow_overwrite
  health_check_id = each.value.health_check_id
  set_identifier  = each.value.set_identifier

  # only set default TTL when not set and not alias record
  ttl = each.value.ttl == null && each.value.alias.name == null ? var.default_ttl : each.value.ttl

  # split TXT records at 255 chars to support >255 char records
  records = can(var.records[each.value.idx].records) ? [for r in var.records[each.value.idx].records :
    each.value.type == "TXT" && length(regexall("(\\\"\\\")", r)) == 0 ?
    join("\"\"", compact(split("{SPLITHERE}", replace(r, "/(.{255})/", "$1{SPLITHERE}")))) : r
  ] : null

  dynamic "weighted_routing_policy" {
    for_each = each.value.weight == null ? [] : [each.value.weight]

    content {
      weight = weighted_routing_policy.value
    }
  }

  dynamic "failover_routing_policy" {
    for_each = each.value.failover == null ? [] : [each.value.failover]

    content {
      type = failover_routing_policy.value
    }
  }

  dynamic "alias" {
    for_each = each.value.alias.name == null ? [] : [each.value.alias]

    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  depends_on = [var.module_depends_on]
}
