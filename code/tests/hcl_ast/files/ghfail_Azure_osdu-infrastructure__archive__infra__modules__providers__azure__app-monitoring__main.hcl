//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

locals {
  scaling_name     = "Instance"
  scaling_operator = "Include"
}

resource "azurerm_monitor_action_group" "appmonitoring" {
  count               = var.action_group_email_receiver == "" ? 0 : 1
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  email_receiver {
    name          = var.action_group_email_receiver_name
    email_address = var.action_group_email_receiver
  }
}

resource "azurerm_monitor_metric_alert" "appmonitoring" {
  count               = var.action_group_email_receiver == "" ? 0 : 1
  name                = var.metric_alert_name
  resource_group_name = azurerm_monitor_action_group.appmonitoring[0].resource_group_name
  scopes              = var.resource_ids
  frequency           = var.metric_alert_frequency
  window_size         = var.metric_alert_period

  criteria {
    metric_namespace = var.metric_alert_criteria_namespace
    metric_name      = var.metric_alert_criteria_name
    aggregation      = var.metric_alert_criteria_aggregation
    operator         = var.metric_alert_criteria_operator
    threshold        = var.metric_alert_criteria_threshold

    dimension {
      name     = local.scaling_name
      operator = local.scaling_operator
      values   = var.monitoring_dimension_values
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.appmonitoring[0].id
  }
}

