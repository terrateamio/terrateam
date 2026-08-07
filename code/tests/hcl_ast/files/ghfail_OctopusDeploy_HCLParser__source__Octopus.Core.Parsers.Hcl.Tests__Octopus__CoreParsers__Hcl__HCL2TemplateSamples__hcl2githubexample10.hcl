###
# AWS Lambda - Notifiy Slack
###

resource "aws_iam_role" "iam_for_notify_slack" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "notify_slack_sns" {
  type        = "zip"
  source_file = "lambda/lambda_notify_slack.js"
  output_path = "/tmp/lambda_notify_slack.js.zip"
}

resource "aws_lambda_function" "notify_slack_sns" {
  filename      = "/tmp/lambda_notify_slack.js.zip"
  function_name = "NotifySlackSNS"
  role          = aws_iam_role.iam_for_notify_slack.arn
  handler       = "lambda_notify_slack.handler"

  source_code_hash = data.archive_file.notify_slack_sns.output_base64sha256

  runtime = "nodejs12.x"

  environment {
    variables = {
      SLACK_WEBHOOK = var.slack_webhook
    }
  }

}

## Allow SNS to call Lambda function

resource "aws_lambda_permission" "notify_slack_warning" {
  statement_id  = "AllowExecutionFromSNSWarningAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_warning.arn
}

resource "aws_lambda_permission" "notify_slack_critical" {
  statement_id  = "AllowExecutionFromSNSCriticalAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_critical.arn
}

## Allow Lambda to create Logs in Cloudwatch

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_notify_slack.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}