resource "aws_cloudwatch_log_group" "covidportal" {
  name       = var.cloudwatch_log_group_name
  kms_key_id = aws_kms_key.cw.arn

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

###
# AWS CloudWatch Metrics - Scaling metrics
###

resource "aws_cloudwatch_metric_alarm" "portal_cpu_utilization_high" {
  alarm_name          = "portal-cpu-utilization-high-warn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "COVID Alert Portal Warning - CPU usage has been over 50% for 4 minutes."

  alarm_actions = [aws_sns_topic.alert_warning.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.covidportal.name
    ServiceName = aws_ecs_service.covidportal.name
  }
}

resource "aws_cloudwatch_metric_alarm" "portal_memory_utilization_high" {
  alarm_name          = "portal-memory-utilization-high-warn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "COVID Alert Portal Warning - Memory usage have been over 50% for 4 minutes."

  alarm_actions = [aws_sns_topic.alert_warning.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.covidportal.name
    ServiceName = aws_ecs_service.covidportal.name
  }
}


###
# AWS CloudWatch Metrics - Code errors
###

resource "aws_cloudwatch_log_metric_filter" "five_hundred_response" {
  name           = "500Response"
  pattern        = "\"HTTP/1.1 5\""
  log_group_name = aws_cloudwatch_log_group.covidportal.name

  metric_transformation {
    name      = "500Response"
    namespace = "covidportal"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "five_hundred_response_warn" {
  alarm_name          = "500ResponseWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.five_hundred_response.name
  namespace           = "covidportal"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  alarm_description   = "COVID Alert Portal Warning - A 5xx HTML error was detected coming from the portal."

  alarm_actions = [aws_sns_topic.alert_warning.arn]
}

resource "aws_cloudwatch_log_metric_filter" "application_error" {
  name           = "ApplicationError"
  pattern        = "Error"
  log_group_name = aws_cloudwatch_log_group.covidportal.name

  metric_transformation {
    name      = "ApplicationError"
    namespace = "covidportal"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "application_error_warn" {
  alarm_name          = "ApplicationErrorWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.application_error.name
  namespace           = "covidportal"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  alarm_description   = "COVID Alert Portal Warning - Django raised an Application Error"

  alarm_actions = [aws_sns_topic.alert_warning.arn]
}


###
# AWS CloudWatch Metrics - Activity Alarms
###

resource "aws_cloudwatch_log_metric_filter" "key_generation_warn" {
  name           = "KeyGenerationWarn"
  pattern        = "\"CRUD event_type:CREATE model:covid_key.covidkey\""
  log_group_name = aws_cloudwatch_log_group.covidportal.name

  metric_transformation {
    name      = "KeyGeneration"
    namespace = "covidportal"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "key_generation_warn" {
  alarm_name          = "KeyGenerationWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.key_generation_warn.name
  namespace           = "covidportal"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "5"
  treat_missing_data  = "notBreaching"
  alarm_description   = "COVID Alert Portal Warning - 6 COVID One Time Keys have been generated in the last hour"
  alarm_actions       = [aws_sns_topic.alert_warning.arn]
}

resource "aws_cloudwatch_log_metric_filter" "key_generation_critical" {
  name           = "KeyGenerationCritical"
  pattern        = "\"CRUD event_type:CREATE model:covid_key.covidkey\""
  log_group_name = aws_cloudwatch_log_group.covidportal.name

  metric_transformation {
    name      = "KeyGeneration"
    namespace = "covidportal"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "key_generation_critical" {
  alarm_name          = "KeyGenerationCritical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.key_generation_critical.name
  namespace           = "covidportal"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "10"
  treat_missing_data  = "notBreaching"
  alarm_description   = "COVID Alert Portal Critical - 11 COVID One Time Keys have been generated in the last hour"
  alarm_actions       = [aws_sns_topic.alert_critical.arn]
}

resource "aws_cloudwatch_log_metric_filter" "site_change" {
  name           = "SiteTableChange"
  pattern        = "\"CRUD\" \"model:sites.site\""
  log_group_name = aws_cloudwatch_log_group.covidportal.name

  metric_transformation {
    name      = "SiteTableChange"
    namespace = "covidportal"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "site_change_warn" {
  alarm_name          = "SiteChangeWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.site_change.name
  namespace           = "covidportal"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  alarm_description   = "COVID Alert Portal Warning - Someone changed something on the Django sites table."
  alarm_actions       = [aws_sns_topic.alert_warning.arn]
}

resource "aws_cloudwatch_log_metric_filter" "account_lockout" {
  name           = "AccountLockout"
  pattern        = "\"AXES: Locking out\""
  log_group_name = aws_cloudwatch_log_group.covidportal.name

  metric_transformation {
    name      = "AccountLockout"
    namespace = "covidportal"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "AccountLockoutWarn" {
  alarm_name          = "AccountLockoutWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.account_lockout.name
  namespace           = "covidportal"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "4"
  treat_missing_data  = "notBreaching"
  alarm_description   = "COVID Alert Portal Warning - 5 user accounts have been locked out in the last hour."
  alarm_actions       = [aws_sns_topic.alert_warning.arn]
}

resource "aws_cloudwatch_log_metric_filter" "invite_lockout" {
  name           = "InviteLockout"
  pattern        = "\"Forbidden: /en/invite/\""
  log_group_name = aws_cloudwatch_log_group.covidportal.name

  metric_transformation {
    name      = "InviteLockout"
    namespace = "covidportal"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "InviteLockoutWarn" {
  alarm_name          = "InviteLockoutWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.invite_lockout.name
  namespace           = "covidportal"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  alarm_description   = "COVID Alert Portal Warning - Someone has tried to invite more than 25 users in the last hour."
  alarm_actions       = [aws_sns_topic.alert_warning.arn]
}

###
# AWS CloudWatch Metrics - DDoS Alarms
###

resource "aws_cloudwatch_metric_alarm" "ddos_detected_covidportal" {
  alarm_name          = "DDoSDetectedCovidPortalWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "COVID Alert Portal Warning - AWS has detected a DDOS attack on the COVID Alert Portal's Load Balancer"

  alarm_actions = [aws_sns_topic.alert_warning.arn]

  dimensions = {
    ResourceArn = aws_lb.covidportal.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_detected_route53" {

  alarm_name          = "DDoSDetectedRoute53Warn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "COVID Alert Portal Warning - AWS has detected a DDOS attack on the COVID Alert Portal's DNS Server"

  alarm_actions = [aws_sns_topic.alert_warning.arn]

  dimensions = {
    ResourceArn = "arn:aws:route53:::hostedzone/${aws_route53_zone.covidportal.zone_id}"
  }
}

###
# AWS CodeDeploy Events
###

resource "aws_cloudwatch_event_target" "codedeploy_sns" {
  target_id = "CodeDeploy_SNS"
  rule      = aws_cloudwatch_event_rule.codedeploy_sns.name
  arn       = aws_sns_topic.alert_warning.arn

  input_transformer {
    input_paths = {
      "status"       = "$.detail.state"
      "deploymentID" = "$.detail.deploymentId"
    }
    input_template = "\"COVID Alert Portal Warning - CloudDeploy has registered a <status> for deployment: <deploymentID>\""
  }
}

resource "aws_cloudwatch_event_rule" "codedeploy_sns" {
  name        = "alert-on-codedeploy-status"
  description = "Alert if CodeDeploy Fails during deployment"

  event_pattern = <<PATTERN
  {
    "source": [
      "aws.codedeploy"
    ],
    "detail-type": [
      "CodeDeploy Deployment State-change Notification"
    ],
    "detail": {
      "state": [
        "FAILURE"
      ]
    }
  }
  PATTERN
}