resource "aws_sns_topic" "alert_warning" {
  name              = "alert-warning"
  kms_master_key_id = aws_kms_key.cw.arn

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_sns_topic" "alert_critical" {
  name              = "alert-critical"
  kms_master_key_id = aws_kms_key.cw.arn

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_sns_topic_subscription" "topic_warning" {
  topic_arn = aws_sns_topic.alert_warning.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack_sns.arn
}

resource "aws_sns_topic_subscription" "topic_critical" {
  topic_arn = aws_sns_topic.alert_critical.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack_sns.arn
}

###
# AWS SNS - CloudWatch Policy
###

resource "aws_sns_topic_policy" "cloudwatch_events_sns" {
  arn    = aws_sns_topic.alert_warning.arn
  policy = data.aws_iam_policy_document.cloudwatch_events_sns_topic_policy.json
}

data "aws_iam_policy_document" "cloudwatch_events_sns_topic_policy" {

  # Default Policy
  statement {
    sid    = "SNS_Default_Policy"
    effect = "Allow"
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    resources = [
      aws_sns_topic.alert_warning.arn
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid    = "SNS_Publish_statement"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.alert_warning.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}