/* Create Bucket for Terraform Lambda Modules */

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.name_prefix}-${var.name_suffix}-${var.environment}-bucket"
  acl    = "private"

  /* This bucket MUST have versioning enabled and encryption */
  versioning {
    enabled = true
  }

  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "null_resource" "sync_to_s3" {
  provisioner "local-exec" {
    command = "aws s3 cp ArchiveItems.zip s3://${aws_s3_bucket.codepipeline_bucket.bucket}/"
  }
}