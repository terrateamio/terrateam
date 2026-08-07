resource "aws_s3_bucket" "logs" {
  bucket = var.bucket
  acl    = "private"
}

resource "aws_iam_role" "firehose_delivery_role" {
  name = "firehose-delivery-role"

  assume_role_policy = <<POLICY
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
POLICY
}

resource "aws_iam_policy" "firehose_delivery_policy" {
  name = "firehose-delivery-policy"
  path = "/"
  description = "Kinesis Firehose delivery policy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "${aws_s3_bucket.logs.arn}",
                "${aws_s3_bucket.logs.arn}/*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "es:DescribeElasticsearchDomain",
                "es:DescribeElasticsearchDomains",
                "es:DescribeElasticsearchDomainConfig",
                "es:ESHttpPost",
                "es:ESHttpPut"
            ],
            "Resource": [
                "${var.es_arn}",
                "${var.es_arn}/*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "es:ESHttpGet"
            ],
            "Resource": [
                "${var.es_arn}/_all/_settings",
                "${var.es_arn}/_cluster/stats",
                "${var.es_arn}/cxcloud*/_mapping/logs",
                "${var.es_arn}/_nodes",
                "${var.es_arn}/_nodes/stats",
                "${var.es_arn}/_nodes/*/stats",
                "${var.es_arn}/_stats",
                "${var.es_arn}/cxcloud*/_stats"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/kinesisfirehose/%FIREHOSE_STREAM_NAME%:log-stream:*"
            ]
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords"
            ],
            "Resource": "arn:aws:kinesis:${var.region}:${var.account_id}:stream/%FIREHOSE_STREAM_NAME%"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "attach_delivery_policy" {
  role       = aws_iam_role.firehose_delivery_role.name
  policy_arn = aws_iam_policy.firehose_delivery_policy.arn
}

data "aws_iam_policy_document" "assume_kinesis_firehose" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.whitelisted_aws_account_arns
    }
  }
}

resource "aws_iam_role" "assume_kinesis_firehose" {
  name               = "KinesisFirehose"
  assume_role_policy = data.aws_iam_policy_document.assume_kinesis_firehose.json
}

resource "aws_iam_role_policy_attachment" "attach_kinesis_firehose" {
  role       = aws_iam_role.assume_kinesis_firehose.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess"
}

resource "aws_kinesis_firehose_delivery_stream" "cxcloud" {
  name        = var.stream_name
  destination = "elasticsearch"

  s3_configuration {
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    bucket_arn         = aws_s3_bucket.logs.arn
    buffer_size        = var.s3_buffer_size
    buffer_interval    = var.s3_buffer_interval
    compression_format = var.s3_compression_format
  }

  elasticsearch_configuration {
    domain_arn         = var.es_arn
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    index_name         = var.es_index_name
    type_name          = var.es_type_name
    buffering_size     = var.es_buffering_size
    buffering_interval = var.es_buffering_interval
    s3_backup_mode     = var.s3_backup_mode
  }
}