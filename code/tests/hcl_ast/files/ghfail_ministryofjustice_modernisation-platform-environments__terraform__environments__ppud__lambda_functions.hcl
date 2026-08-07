#######################################################################
# Lambda Functions
#######################################################################

locals {
  # Lambda environment configurations
  lambda_environments = {
    development = {
      condition   = local.is-development
      s3_bucket   = "moj-infrastructure-dev"
      account_key = "ppud-development" # checkov:skip=CKV_SECRET_6: "Environment identifier, not a secret"
    }
    preproduction = {
      condition   = local.is-preproduction
      s3_bucket   = "moj-infrastructure-uat"
      account_key = "ppud-preproduction" # checkov:skip=CKV_SECRET_6: "Environment identifier, not a secret"
    }
    production = {
      condition   = local.is-production
      s3_bucket   = "moj-infrastructure"
      account_key = "ppud-production" # checkov:skip=CKV_SECRET_6: "Environment identifier, not a secret"
    }
  }

  # Lambda function configurations
  lambda_functions = {
    check_certificate_expiration = {
      description  = "Function to check certificate expiration date and send a reminder for any under 30 days."
      role_key     = "get_certificate_expiry"
      environments = ["development", "preproduction", "production"]
      runtime      = "python3.13"
      permissions = [{
        principal         = "lambda.alarms.cloudwatch.amazonaws.com"
        source_arn_suffix = "alarm:*"
      }]
      environment = {
        variables = {
          EXPIRY_DAYS = "30"
          SNS_TOPIC_ARN = {
            development   = "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:ppud-dev-cw-alerts"
            preproduction = "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:ppud-uat-cw-alerts"
            production    = "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:ppud-prod-cw-alerts"
          }
        }
      }
    }
    terminate_cpu_process = {
      description  = "Function to terminate an application process due to high CPU utilisation on an EC2 instance."
      role_key     = "invoke_ssm"
      environments = ["development", "preproduction", "production"]
      permissions = [{
        principal         = "lambda.alarms.cloudwatch.amazonaws.com"
        source_arn_suffix = "alarm:*"
      }]
    }
    send_cpu_notification = {
      description  = "Function to send an email notification when triggered by high CPU utilisation on an EC2 instance."
      role_key     = "invoke_ssm"
      environments = ["development", "preproduction", "production"]
      permissions = [{
        principal         = "lambda.alarms.cloudwatch.amazonaws.com"
        source_arn_suffix = "alarm:*"
      }]
    }
    send_cpu_graph = {
      description  = "Function to retrieve, graph and email CPU utilisation on an EC2 instance."
      role_key     = "get_cloudwatch"
      environments = ["development", "production"]
      layers       = ["numpy", "pillow", "matplotlib"]
      vpc_config   = { prod = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    wam_waf_analysis = {
      description  = "Function to analyse WAM WAF ACL traffic and email a report."
      role_key     = "get_cloudwatch"
      environments = ["development", "preproduction", "production"]
      layers       = ["numpy", "pillow", "requests", "matplotlib"]
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    securityhub_critical_report = {
      description  = "Function to email a summary of critical CVEs found in AWS Security Hub."
      role_key     = "get_securityhub_data"
      environments = ["development", "preproduction", "production"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "securityhub.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    securityhub_monthly_report = {
      description  = "Function to email a summary of all AWS Security Hub CVEs created, resolved and suppressed in a given month."
      role_key     = "get_securityhub_data"
      environments = ["development", "preproduction", "production"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "securityhub.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    ses_logging = {
      description  = "Function to allow logging of outgoing emails via SES."
      role_key     = "get_ses_logging"
      environments = ["development", "preproduction"]
      permissions = [{
        principal           = "sns.amazonaws.com"
        source_arn_resource = "ses_logging"
      }]
    }
    disable_cpu_alarm = {
      description  = "Function to disable Cloudwatch CPU alerts."
      role_key     = "get_cloudwatch"
      environments = ["production"]
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    enable_cpu_alarm = {
      description  = "Function to enable Cloudwatch CPU alerts."
      role_key     = "get_cloudwatch"
      environments = ["production"]
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    ppud_email_report = {
      description  = "Function to analyse, graph and email the email usage on the smtp mail relays."
      role_key     = "get_cloudwatch"
      environments = ["production"]
      layers       = ["numpy", "pillow", "matplotlib"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    ppud_elb_count_report = {
      description  = "Function to retrieve, graph and email the utilisation of the PPUD ELB."
      role_key     = "get_cloudwatch"
      environments = ["production"]
      layers       = ["numpy", "pillow", "matplotlib"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    wam_elb_count_report = {
      description  = "Function to retrieve, graph and email the utilisation of the WAM ELB."
      role_key     = "get_cloudwatch"
      environments = ["production"]
      layers       = ["numpy", "pillow", "matplotlib"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    ppud_elb_get_trt_data = {
      description  = "Function to retrieve PPUD ELB target response time data from Cloudwatch and send it to S3."
      role_key     = "get_elb_metrics"
      environments = ["production"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    ppud_elb_calculate_trt_data = {
      description  = "Function to retrieve PPUD ELB target response time data from S3, calculate the monthly average target response time and email a report to end users."
      role_key     = "get_elb_metrics"
      environments = ["production"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    ppud_elb_graph_trt_data = {
      description  = "Function to retrieve PPUD ELB daily target response time data from Cloudwatch, graph it and email it to end users."
      role_key     = "get_cloudwatch"
      environments = ["production"]
      layers       = ["numpy", "pillow", "matplotlib"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    wam_elb_graph_trt_data = {
      description  = "Function to retrieve WAM ELB daily target response time data from Cloudwatch, graph it and email it to end users."
      role_key     = "get_cloudwatch"
      environments = ["production"]
      layers       = ["numpy", "pillow", "matplotlib"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    ppud_elb_get_uptime_data = {
      description  = "Function to retrieve PPUD ELB uptime data from Cloudwatch and send it to S3."
      role_key     = "get_elb_metrics"
      environments = ["production"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    ppud_elb_calculate_uptime_data = {
      description  = "Function to retrieve PPUD ELB uptime data from S3, calculate the monthly average uptime and email a report to end users."
      role_key     = "get_elb_metrics"
      environments = ["production"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    ssm_patch_notification = {
      description  = "Function to send email notification when SSM patching completes."
      role_key     = "ssm_patch_notification"
      environments = ["development", "preproduction", "production"]
      runtime      = "python3.13"
      permissions = [{
        principal         = "events.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    disk_info_report = {
      description  = "Function to retrieve, format and email a report on the disk utilisation of all Windows EC2 instances."
      role_key     = "get_cloudwatch"
      environments = ["production"]
      layers       = ["numpy", "pillow", "matplotlib"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    wam_web_traffic_analysis = {
      description  = "Function to analyse IIS logs from S3, format the data and output a report in Excel to S3."
      timeout      = 900
      memory_size  = 1024
      role_key     = "get_cloudwatch"
      environments = ["production"]
      layers       = ["beautifulsoup", "xlsxwriter", "requests"]
      vpc_config   = { production = true }
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    sync_ssm_to_waf = {
      description  = "Function to synchronize ssm parameter store with WAF ip sets."
      role_key     = "sync_ssm_to_waf"
      environments = ["development", "preproduction", "production"]
      permissions = [{
        principal         = "events.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    check_elb_trt_alarm = {
      description  = "Function to check alarm state of High-Target-Response-Time-WAM-ELB alarm and generate subsequent alerts."
      role_key     = "check_elb_trt_alarm"
      environments = ["production"]
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    suppress_securityhub_findings = {
      description  = "Function to suppress security hub findings with a Compliance Status of NOT_AVAILABLE."
      role_key     = "suppress_sechub_findings"
      environments = ["development", "preproduction", "production"]
      permissions = [{
        principal         = "securityhub.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
    waf_web_acl_bot_analysis = {
      description  = "Function to analyse WAM WAF Web ACL rule AWSManagedRulesBotControlRuleSet for bot traffic and email a report."
      role_key     = "get_waf_web_acl"
      environments = ["development", "preproduction"]
      permissions = [{
        principal         = "cloudwatch.amazonaws.com"
        source_arn_suffix = "*"
      }]
    }
  }

  # Flatten lambda functions with environments
  lambda_instances = flatten([
    for func_name, func_config in local.lambda_functions : [
      for env in func_config.environments : {
        key        = "${func_name}_${env}"
        func_name  = func_name
        env        = env
        config     = func_config
        env_config = local.lambda_environments[env]
      } if local.lambda_environments[env].condition
    ]
  ])

  lambda_instances_map = {
    for instance in local.lambda_instances : instance.key => instance
  }

  # Common lambda configuration
  lambda_defaults = {
    runtime                        = "python3.12"
    timeout                        = 300
    reserved_concurrent_executions = 5
    tracing_mode                   = "Active"
    log_retention_days             = 30
  }

  # Dead letter SQS queue
  dlq_arn = data.aws_sqs_queue.lambda_function_dead_letter_queue.arn

  # Lambda ARNs
  klayers_account_id = data.aws_ssm_parameter.klayers_account.value

  layer_arns = {
    numpy  = "arn:aws:lambda:eu-west-2:${local.klayers_account_id}:layer:Klayers-p312-numpy:8"
    pillow = "arn:aws:lambda:eu-west-2:${local.klayers_account_id}:layer:Klayers-p312-pillow:1"
  }

}

#######################################################################
# Lambda Function Resource Statement
#######################################################################

resource "aws_lambda_function" "lambda_functions" {
  for_each = local.lambda_instances_map

  # checkov:skip=CKV_AWS_173: "Encryption is not required as no sensitive data is processed through it"
  # checkov:skip=CKV_AWS_116: "Dead Letter queues to be enabled later"
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"

  description                    = each.value.config.description
  s3_bucket                      = each.value.env_config.s3_bucket
  s3_key                         = "lambda/functions/${each.value.func_name}_${each.value.env}.zip"
  function_name                  = "${each.value.func_name}_${each.value.env}"
  role                           = aws_iam_role.lambda_role_v2["${each.value.config.role_key}_${each.value.env}"].arn
  handler                        = "${each.value.func_name}_${each.value.env}.lambda_handler"
  runtime                        = local.lambda_defaults.runtime
  timeout                        = try(each.value.config.timeout, local.lambda_defaults.timeout)
  reserved_concurrent_executions = local.lambda_defaults.reserved_concurrent_executions
  memory_size                    = try(each.value.config.memory_size, null)

  # Lambda dead letter sqs queues
  dead_letter_config {
    target_arn = local.dlq_arn
  }

  tracing_config {
    mode = local.lambda_defaults.tracing_mode
  }

  # Conditional layers
  layers = try(each.value.config.layers, null) != null ? [
    for layer in each.value.config.layers :
    contains(keys(local.lambda_layers), layer) ?
    aws_lambda_layer_version.lambda_layers[layer].arn :
    contains(keys(local.layer_arns), layer) ?
    local.layer_arns[layer] :
    null
  ] : null

  # Conditional VPC configuration
  dynamic "vpc_config" {
    for_each = each.value.env == "production" ? [1] : []
    content {
      subnet_ids         = [data.aws_subnet.private_subnets_b.id]
      security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
    }
  }

  # Dynamic environment variables
  dynamic "environment" {
    for_each = try(each.value.config.environment, null) != null ? [each.value.config.environment] : []
    content {
      variables = merge(
        environment.value.variables,
        {
          SNS_TOPIC_ARN = environment.value.variables.SNS_TOPIC_ARN[each.value.env]
        }
      )
    }
  }

  # Tags
  tags = {
    Function    = each.value.func_name
    Environment = each.value.env
  }
}

#######################################################################
# Lambda Permissions
#######################################################################

resource "aws_lambda_permission" "lambda_permissions" {
  for_each = {
    for k, v in local.lambda_instances_map : k => v
    if length(v.config.permissions) > 0
  }

  statement_id  = "AllowInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_functions[each.key].function_name
  principal     = each.value.config.permissions[0].principal

  source_arn = try(each.value.config.permissions[0].source_arn_resource, null) != null ? (
    "arn:aws:sns:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:${each.value.config.permissions[0].source_arn_resource}_${each.value.env}"
    ) : (
    "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids[each.value.env_config.account_key]}:${each.value.config.permissions[0].source_arn_suffix}"
  )
}

#######################################################################
# CloudWatch Log Groups
#######################################################################

resource "aws_cloudwatch_log_group" "lambda_log_groups" {
  for_each = local.lambda_instances_map

  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."

  name              = "/aws/lambda/${each.value.func_name}_${each.value.env}"
  retention_in_days = local.lambda_defaults.log_retention_days
}
