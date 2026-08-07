###
# AWS Kinesis Firehose - IAM Role
###
resource "aws_iam_role" "firehose_waf_logs" {
  name = "firehose_waf_logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

###
# AWS Kinesis Firehose - IAM Policy
###
resource "aws_iam_role_policy" "firehose_waf_logs" {
  name   = "firehose-waf-logs-policy"
  role   = aws_iam_role.firehose_waf_logs.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.firehose_waf_logs.arn}",
        "${aws_s3_bucket.firehose_waf_logs.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "iam:CreateServiceLinkedRole",
      "Resource": "arn:aws:iam::*:role/aws-service-role/wafv2.amazonaws.com/AWSServiceRoleForWAFV2Logging"
    }
  ]
}
EOF
}

###
# AWS Kinesis Firehose - Delivery Stream
###
resource "aws_kinesis_firehose_delivery_stream" "firehose_waf_logs" {
  name        = "aws-waf-logs-covid-portal"
  destination = "s3"
  server_side_encryption {
    enabled = true
  }

  s3_configuration {
    role_arn   = aws_iam_role.firehose_waf_logs.arn
    bucket_arn = aws_s3_bucket.firehose_waf_logs.arn
  }
}
