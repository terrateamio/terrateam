locals {
  dimensions = {
    "ClusterName" = var.cluster_name
    "PodName"     = var.pod_name
    "Namespace"   = var.namespace
  }

  cpu     = <<EOF
      {
        "type": "metric",
        "x": 0,
        "y": 0,
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", "${var.cluster_name}", "PodName", "${var.pod_name}", "Namespace", "${var.namespace}"]
          ],
          "period": ${var.cpu_period},
          "stat": "${var.cpu_statistic}",
          "region": "${var.dashboard_region}",
          "title": "${var.pod_name} CPU_Utilization"
          }
      }
EOF
  memory  = <<EOF
      {
        "type": "metric",
        "x": 0,
        "y": 0,
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
              ["ContainerInsights", "pod_memory_utilization", "ClusterName", "${var.cluster_name}", "PodName", "${var.pod_name}", "Namespace", "${var.namespace}"]
          ],
          "period": ${var.memory_period},
          "stat": "${var.memory_statistic}",
          "region": "${var.dashboard_region}",
          "title": "${var.pod_name} Memory_Utilization"
          }
      }
EOF
  network = <<EOF
    {
        "type": "metric",
        "x": 0,
        "y": 0,
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
              ["ContainerInsights", "pod_network_tx_bytes", "ClusterName", "${var.cluster_name}", "PodName","${var.pod_name}", "Namespace","${var.namespace}"],
              ["ContainerInsights", "pod_network_rx_bytes", "ClusterName", "${var.cluster_name}", "PodName","${var.pod_name}", "Namespace","${var.namespace}"]
          ],
          "period": ${var.network_period},
          "stat": "${var.network_statistic}",
          "region": "${var.dashboard_region}",
          "title": "${var.pod_name} Netowrk_Utilization"
          }
      }
EOF
  restart = <<EOF
      {
        "type": "metric",
        "x": 0,
        "y": 0,
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
              ["ContainerInsights", "pod_number_of_container_restarts", "ClusterName", "${var.cluster_name}", "PodName","${var.pod_name}", "Namespace","${var.namespace}"]
          ],
          "period": ${var.restart_period},
          "stat": "${var.restart_statistic}",
          "region": "${var.dashboard_region}",
          "title": "${var.pod_name} Restarts"
          }
      }
  EOF
  error   = <<EOF
      {
        "type": "metric",
        "x": 0,
        "y": 0,
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
              ["LogGroupFilter", "errorfilter"]
          ],
          "period": ${var.error_period},
          "stat": "${var.error_statistic}",
          "region": "${var.dashboard_region}",
          "title": "${var.pod_name} Error_Count"
          }
      }
  EOF

  null          = ""
  comma         = ","
  cpu_dashboard = var.enable_cpu_threshold ? local.cpu : local.null

  add_comma_memory = "${local.comma} ${local.memory}"
  memory_dashboard = var.enable_memory_threshold ? "${var.enable_cpu_threshold ? local.add_comma_memory : local.memory}" : local.null

  add_comma_network = "${local.comma} ${local.network}"
  network_dashboard = var.enable_network_threshold ? "${var.enable_memory_threshold ? local.add_comma_network : "${var.enable_cpu_threshold ? local.add_comma_network : local.network}"}" : local.null

  add_comma_restart = "${local.comma} ${local.restart}"
  restart_dashboard = var.enable_restart_threshold ? "${var.enable_network_threshold ? local.add_comma_restart : var.enable_memory_threshold ? local.add_comma_restart : var.enable_cpu_threshold ? local.add_comma_restart : local.restart}" : local.null

  add_comma_error = "${local.comma} ${local.error}"
  error_dashboard = var.enable_error_filter ? "${var.enable_restart_threshold ? local.add_comma_error : var.enable_network_threshold ? local.add_comma_error : var.enable_memory_threshold ? local.add_comma_error : var.enable_cpu_threshold ? local.add_comma_error : local.error}" : local.null



  dashboard_body1 = <<EOF
  {
    "widgets": [
      ${local.cpu_dashboard}
      ${local.memory_dashboard}
      ${local.network_dashboard}
      ${local.restart_dashboard}
      ${local.error_dashboard}
    ]
  }
  EOF

}

resource "aws_cloudwatch_dashboard" "error_metric_include2" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = "${var.env}-${var.pod_name}-dashboard"

  dashboard_body = local.dashboard_body1
}


// CPU ALARM
module "cloudwatchalarm_cpu" {
  count      = var.enable_cpu_threshold ? 1 : 0
  source     = "../cloudwatch-alarm-notify"
  alarm_name = "${var.env}_${var.pod_name}_cpu_utilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = var.cpu_period
  namespace           = "ContainerInsights"
  unit                = var.cpu_unit
  metric_name         = "pod_cpu_utilization"
  statistic           = var.cpu_statistic
  threshold           = var.cpu_threshold
  treat_missing_data  = "notBreaching"
  dimensions          = local.dimensions

  # Slack information
  slack_hook_url                         = var.slack_hook_url
  slack_channel                          = var.slack_channel
  slack_username                         = var.slack_username
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  # SNS Topic
  sns_subscription_email_address_list = var.sns_subscription_email_address_list
  sns_subscription_phone_number_list  = var.sns_subscription_phone_number_list
  sms_message_body                    = var.sms_message_body

  ### Opsgenie endpoints
  opsgenie_endpoint = var.opsgenie_endpoints
}

// MEMORY ALARM
module "cloudwatchalarm_memory" {
  count      = var.enable_memory_threshold ? 1 : 0
  source     = "../cloudwatch-alarm-notify"
  alarm_name = "${var.env}_${var.pod_name}_memory_utilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = var.memory_period
  namespace           = "ContainerInsights"
  unit                = var.memory_unit
  metric_name         = "pod_memory_utilization"
  statistic           = var.memory_statistic
  threshold           = var.memory_threshold
  treat_missing_data  = "notBreaching"
  dimensions          = local.dimensions

  # Slack information
  slack_hook_url                         = var.slack_hook_url
  slack_channel                          = var.slack_channel
  slack_username                         = var.slack_username
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # SNS Topic
  sns_subscription_email_address_list = var.sns_subscription_email_address_list
  sns_subscription_phone_number_list  = var.sns_subscription_phone_number_list
  sms_message_body                    = var.sms_message_body

  ### Opsgenie endpoints
  opsgenie_endpoint = var.opsgenie_endpoints
}

// Log Filter
module "cloudwatch_log_metric_filter" {
  count  = var.enable_error_filter ? 1 : 0
  source = "../cloudwatch-log-metric"

  name             = "${var.env}_${var.pod_name}"
  filter_pattern   = var.error_filter_pattern
  create_log_group = false
  log_group_name   = var.log_group_name
  metric_name      = "errorfilter"
}

// Error Metric
module "cloudwatchalarm_error" {
  count      = var.enable_error_filter ? 1 : 0
  source     = "../cloudwatch-alarm-notify"
  alarm_name = "${var.env}_${var.pod_name}_error_utilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = var.error_period
  namespace           = "LogGroupFilter"
  unit                = var.error_unit
  metric_name         = "errorfilter"
  statistic           = var.error_statistic
  threshold           = var.error_threshold
  treat_missing_data  = "notBreaching"
  dimensions          = local.dimensions

  # Slack information
  slack_hook_url                         = var.slack_hook_url
  slack_channel                          = var.slack_channel
  slack_username                         = var.slack_username
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # SNS Topic
  sns_subscription_email_address_list = var.sns_subscription_email_address_list
  sns_subscription_phone_number_list  = var.sns_subscription_phone_number_list
  sms_message_body                    = var.sms_message_body

  ### Opsgenie endpoints
  opsgenie_endpoint = var.opsgenie_endpoints
}

// Network Metric
module "cloudwatchalarm_network_tx" {
  count      = var.enable_network_threshold ? 1 : 0
  source     = "../cloudwatch-alarm-notify"
  alarm_name = "${var.env}_${var.pod_name}_network_tx_utilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = var.network_period
  namespace           = "ContainerInsights"
  unit                = var.network_unit
  metric_name         = "pod_network_tx_bytes"
  statistic           = var.network_statistic
  threshold           = var.network_threshold
  treat_missing_data  = "notBreaching"
  dimensions          = local.dimensions

  # Slack information
  slack_hook_url                         = var.slack_hook_url
  slack_channel                          = var.slack_channel
  slack_username                         = var.slack_username
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  # SNS Topic
  sns_subscription_email_address_list = var.sns_subscription_email_address_list
  sns_subscription_phone_number_list  = var.sns_subscription_phone_number_list
  sms_message_body                    = var.sms_message_body

  ### Opsgenie endpoints
  opsgenie_endpoint = var.opsgenie_endpoints
}

module "cloudwatchalarm_network_rx" {
  count      = var.enable_network_threshold ? 1 : 0
  source     = "../cloudwatch-alarm-notify"
  alarm_name = "${var.env}_${var.pod_name}_network_rx_utilization"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = var.network_period
  namespace           = "ContainerInsights"
  unit                = var.network_unit
  metric_name         = "pod_network_rx_bytes"
  statistic           = var.network_statistic
  threshold           = var.network_threshold
  treat_missing_data  = "notBreaching"
  dimensions          = local.dimensions

  # Slack information
  slack_hook_url                         = var.slack_hook_url
  slack_channel                          = var.slack_channel
  slack_username                         = var.slack_username
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  # SNS Topic
  sns_subscription_email_address_list = var.sns_subscription_email_address_list
  sns_subscription_phone_number_list  = var.sns_subscription_phone_number_list
  sms_message_body                    = var.sms_message_body

  ### Opsgenie endpoints
  opsgenie_endpoint = var.opsgenie_endpoints
}

// Pod Restarts
module "cloudwatchalarm_restart_count" {
  count      = var.enable_restart_threshold ? 1 : 0
  source     = "../cloudwatch-alarm-notify"
  alarm_name = "${var.env}_${var.pod_name}_restart_count"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  period              = var.restart_period
  namespace           = "ContainerInsights"
  unit                = var.restart_unit
  metric_name         = "pod_number_of_container_restarts"
  statistic           = var.restart_statistic
  threshold           = var.restart_threshold
  treat_missing_data  = "breaching"
  dimensions          = local.dimensions

  # Slack information
  slack_hook_url                         = var.slack_hook_url
  slack_channel                          = var.slack_channel
  slack_username                         = var.slack_username
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  # SNS Topic
  sns_subscription_email_address_list = var.sns_subscription_email_address_list
  sns_subscription_phone_number_list  = var.sns_subscription_phone_number_list
  sms_message_body                    = var.sms_message_body

  ### Opsgenie endpoints
  opsgenie_endpoint = var.opsgenie_endpoints
}
