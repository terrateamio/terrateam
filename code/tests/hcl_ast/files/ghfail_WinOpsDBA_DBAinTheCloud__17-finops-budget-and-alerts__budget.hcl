resource "azurerm_monitor_action_group" "mag1" {
  name                = "Monitor action group"
  resource_group_name = azurerm_resource_group.rg1.name
  short_name          = "mag"
}

locals {
  notification_email = "nikos.tsirmirakis@winopsdba.com"
}

# Forecast

locals {

  budget_forecast_notifications = {
    80.0  = { operator = "GreaterThanOrEqualTo", contact_emails = [local.notification_email] }
    90.0  = { operator = "GreaterThanOrEqualTo", contact_emails = [local.notification_email] }
    100.0 = { operator = "GreaterThanOrEqualTo", contact_emails = [local.notification_email] }
    120.0 = { operator = "GreaterThanOrEqualTo", contact_emails = [local.notification_email] }
  }
}

resource "azurerm_consumption_budget_resource_group" "cbrgf" {
  name              = "${azurerm_resource_group.rg1.name}-m-forecast-${var.budget_amount}"
  resource_group_id = azurerm_resource_group.rg1.id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = "2023-10-01T00:00:00Z"
  }

  filter {
    dimension {
      name = "ResourceId"
      values = [
        azurerm_monitor_action_group.mag1.id,
      ]
    }
  }

  dynamic "notification" {
    for_each = local.budget_forecast_notifications
    content {
      enabled        = true
      threshold      = notification.key
      threshold_type = "Forecasted"
      operator       = notification.value.operator
      contact_emails = notification.value.contact_emails
      contact_groups = [azurerm_monitor_action_group.mag1.id]
      contact_roles  = ["Owner"]
    }
  }
}

# Actual

locals {
  budget_actual_notifications = {
    80.0  = { operator = "GreaterThanOrEqualTo", contact_emails = [local.notification_email] }
    90.0  = { operator = "GreaterThanOrEqualTo", contact_emails = [local.notification_email] }
    100.0 = { operator = "GreaterThanOrEqualTo", contact_emails = [local.notification_email] }
    120.0 = { operator = "GreaterThanOrEqualTo", contact_emails = [local.notification_email] }
  }
}

resource "azurerm_consumption_budget_resource_group" "cbrga" {
  name              = "${azurerm_resource_group.rg1.name}-m-actual-${var.budget_amount}"
  resource_group_id = azurerm_resource_group.rg1.id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = "2023-10-01T00:00:00Z"
  }

  filter {
    dimension {
      name = "ResourceId"
      values = [
        azurerm_monitor_action_group.mag1.id,
      ]
    }
  }

  dynamic "notification" {
    for_each = local.budget_actual_notifications
    content {
      enabled        = true
      threshold      = notification.key
      threshold_type = "Actual"
      operator       = notification.value.operator
      contact_emails = notification.value.contact_emails
      contact_groups = [azurerm_monitor_action_group.mag1.id]
      contact_roles  = ["Owner"]
    }
  }
}
