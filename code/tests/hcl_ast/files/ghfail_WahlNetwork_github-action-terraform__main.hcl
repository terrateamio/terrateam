## ========================================================================== ##
#  Terraform State S3 Bucket                                                   #
## ========================================================================== ##

# Provides the AWS account ID to other resources
# Interpolate: data.aws_caller_identity.current.account_id
data "aws_caller_identity" "current" {}

# Provides an AWS KMS Key to encrypt/decrypt the S3 Bucket
resource "aws_kms_key" "this" {
  description             = "Used to encrypt and decrypt the Terraform State S3 Bucket"
  deletion_window_in_days = 10
  tags = {
    Name        = "${var.aws_root_name}-kms-teraform-${var.aws_region_name}"
    Environment = var.aws_environment_name
    Source      = var.aws_source_name
  }
  policy = <<EOF
{
    "Id": "key-consolepolicy-3",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                  "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.aws_kms_admin}"
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                  "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.aws_kms_user}"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# Provides an alias for the newly created AWS KMS key
resource "aws_kms_alias" "this" {
  name          = "alias/${var.aws_root_name}-kms-terraform-${var.aws_region_name}"
  target_key_id = aws_kms_key.this.id
}

# Provides an S3 bucket for storing Terraform state files
resource "aws_s3_bucket" "this" {
  bucket = "${var.aws_root_name}-s3-terraform-${var.aws_region_name}"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.this.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  tags = {
    Name        = "${var.aws_root_name}-s3-terraform-${var.aws_region_name}"
    Environment = var.aws_environment_name
    Source      = var.aws_source_name
    Answer      = "42"
    #tfsec:ignore:AWS002
  }
}

# Provides additional layers of security to block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

terraform {
  backend "s3" {
    bucket = "demo-s3-terraform-use1"
    key    = "github-actions-example/terraform.tfstate"
    region = "us-east-1"
  }
}
