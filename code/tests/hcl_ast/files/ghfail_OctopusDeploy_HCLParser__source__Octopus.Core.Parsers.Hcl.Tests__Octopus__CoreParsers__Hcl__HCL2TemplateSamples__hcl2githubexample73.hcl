terraform {
  backend "s3" {
    key     = "common/lambda/cloudwatch-log-destination"
    encrypt = true
  }
}

terraform {
  required_version = ">= 0.12"
}

locals {
  common_tags = {
    Owner       = "global"
    Environment = terraform.workspace
  }
}

data "terraform_remote_state" "master" {
  backend = "s3"
  config = {
    bucket   = "terraform.bhavik.io"
    key      = "common/master"
    region   = var.aws_default_region
    profile  = var.profile
    role_arn = "arn:aws:iam::${var.operations_account_id}:role/${var.role_name}"
  }
}

provider "aws" {
  region  = var.aws_default_region
  version = "~> 2.8.0"
  profile = var.profile

  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/${var.role_name}"
    session_name = "terraform"
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda_write_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.lambda.arn,
    ]
  }
}

data "aws_iam_policy_document" "subscription_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:PutSubscriptionFilter",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "CloudWatchSubscriptionFilterLambda"
  description        = "Used by CloudWatch Destination Lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = merge(local.common_tags, var.tags)
}

resource "aws_iam_role_policy" "lambda_write_logs" {
  name   = "CloudwatchLogWritePermissions"
  role   = aws_iam_role.lambda.name
  policy = data.aws_iam_policy_document.lambda_write_logs.json
}

resource "aws_iam_role_policy" "lambda_subscription_filter_policy" {
  name   = "AllowPutSubscriptionFilterPolicy"
  role   = aws_iam_role.lambda.name
  policy = data.aws_iam_policy_document.subscription_policy.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = var.log_retention_period
  kms_key_id        = data.terraform_remote_state.master.outputs.default_kms_key_arn
  tags              = merge(local.common_tags, var.tags)
}

resource "aws_cloudwatch_log_subscription_filter" "lambda" {
  name            = "DefaultLogDestination"
  log_group_name  = aws_cloudwatch_log_group.lambda.name
  filter_pattern  = ""
  destination_arn = data.terraform_remote_state.master.outputs.log_destination_arn
  distribution    = "ByLogStream"
}

resource "aws_lambda_function" "lambda" {
  function_name = "CloudWatchLogDestination"
  description   = "Sets the default cloudwatch log subscription filter"
  role          = aws_iam_role.lambda.arn
  handler       = "main"
  runtime       = "go1.x"
  memory_size   = 128
  kms_key_arn   = data.terraform_remote_state.master.outputs.default_kms_key_arn
  filename      = "cloudwatch-log-destination${var.lambda_version}.zip"
  publish       = true
  source_code_hash = filebase64sha256(
  format("cloudwatch-log-destination%s.zip", var.lambda_version),
  )

  environment {
    variables = {
      DESTINATION_ARN = data.terraform_remote_state.master.outputs.log_destination_arn
    }
  }
  tags = merge(local.common_tags, var.tags)
}

resource "aws_cloudwatch_event_rule" "subscription_filter" {
  name        = "LogSubscriptionFilterModifications"
  description = "Captures when log groups are created or the subscription filters are modified"
  tags        = merge(local.common_tags, var.tags)

  event_pattern = <<PATTERN
{
  "source": [
    "aws.logs"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "logs.amazonaws.com"
    ],
    "eventName": [
      "CreateLogGroup",
      "PutSubscriptionFilter",
      "DeleteSubscriptionFilter"
    ]
  }
}
PATTERN

}

resource "aws_cloudwatch_event_target" "subscription_lambda" {
  rule = aws_cloudwatch_event_rule.subscription_filter.name
  arn = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id = "AllowSubscriptionFilterLambdaExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.subscription_filter.arn
}