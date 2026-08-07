data "azurerm_resource_group" "svcplan" {
  name = var.resource_group_name
}

resource "azurerm_app_service_plan" "svcplan" {
  name                = var.service_plan_name
  location            = data.azurerm_resource_group.svcplan.location
  resource_group_name = var.resource_group_name
  kind                = var.service_plan_kind
  tags                = var.resource_tags
  reserved            = var.service_plan_kind == "Linux" ? true : var.service_plan_reserved

  sku {
    tier     = var.service_plan_tier
    size     = var.service_plan_size
    capacity = var.service_plan_capacity
  }
}

resource "azurerm_monitor_autoscale_setting" "app_service_auto_scale" {
  name                = "${var.service_plan_name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = data.azurerm_resource_group.svcplan.location
  target_resource_id  = azurerm_app_service_plan.svcplan.id

  profile {
    name = "Scale on CPU usage"

    capacity {
      default = 1
      minimum = var.autoscale_capacity_minimum
      maximum = azurerm_app_service_plan.svcplan.maximum_number_of_workers
    }

    rule {
      metric_trigger {
        metric_name        = var.autoscale_rule_out_metric_name
        metric_resource_id = azurerm_app_service_plan.svcplan.id
        time_grain         = "PT1M"
        statistic          = var.autoscale_rule_out_statistic
        time_window        = "PT5M"
        time_aggregation   = var.autoscale_rule_out_statistic
        operator           = var.autoscale_rule_out_operator
        threshold          = var.autoscale_rule_out_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = var.autoscale_rule_out_action_change_count
        cooldown  = "PT10M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = var.autoscale_rule_in_metric_name
        metric_resource_id = azurerm_app_service_plan.svcplan.id
        time_grain         = "PT1M"
        statistic          = var.autoscale_rule_in_statistic
        time_window        = "PT5M"
        time_aggregation   = var.autoscale_rule_in_statistic
        operator           = var.autoscale_rule_in_operator
        threshold          = var.autoscale_rule_in_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = var.autoscale_rule_in_action_change_count
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
    }
  }
}