locals {
  spec_json           = var.instance.spec
  userspecified_rules = lookup(local.spec_json, "rules", {})

  #All metadata values
  all_metadata = {
    labels = merge({
      alert_group_name = var.instance_name
      role             = "alert-rules"
    }, lookup(var.instance.metadata, "labels", {}))
    annotations = merge({
      owner = "facets"
    }, lookup(var.instance.metadata, "annotations", {}))
    name      = "${var.instance_name}-alert-group"
    namespace = var.environment.namespace
  }

  # All rules grouped in all_rules variable
  all_rules = [
    for rule_name, rule_object in local.userspecified_rules :
    {
      alert = rule_name
      expr  = rule_object.expr
      for   = rule_object.for
      labels = merge(lookup(rule_object, "labels", {}), {
        "resource_type" = rule_object.resource_type,
        "resource_name" = rule_object.resource_name,
        "resourceType"  = rule_object.resource_type,
        "resourceName"  = rule_object.resource_name,
        "alert_type"    = lookup(rule_object, "alert_type", null)
        "severity"      = lookup(rule_object, "severity", null)
      })
      annotations = merge(lookup(rule_object, "annotations", {}), {
        message = rule_object.message
        summary = rule_object.summary
      })
    } if !lookup(rule_object, "disabled", false)
  ]

  # Manifest for the actual resource
  alert_manifest = {
    apiVersion = "monitoring.coreos.com/v1",
    kind       = "PrometheusRule"
    metadata   = local.all_metadata
    spec = {
      groups = [
        {
          name  = "${var.instance_name}-alert-rules"
          rules = local.all_rules
        }
      ]
    }
  }

  # Manifest to be used after yamlencode for parsing
  alert_manifest_yaml = yamlencode(local.alert_manifest)

  # Manifest clubed with anyResources object for rendering
  helm_values = {
    anyResources = {
      facets_alert = local.alert_manifest_yaml
    }
  }
  helm_values_yaml = yamlencode(local.helm_values)

}