locals {
  bucket_name = "celsus.isnan.eu"
}

data "template_file" "web_app_bucket_policy" {
  template = <<EOF
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AddPerm",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$${bucket}/*"
    }
  ]
}
EOF


  vars = {
    bucket = local.bucket_name
  }
}

resource "aws_s3_bucket" "web_app" {
  bucket = local.bucket_name
  acl = "public-read"
  region = var.region

  policy = data.template_file.web_app_bucket_policy.rendered

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET"]
    max_age_seconds = "3000"
    allowed_headers = ["Authorization", "Content-Length"]
  }

  tags = local.tags
}

locals {
  s3_origin_id = "celsus-web-client"
}

resource "aws_cloudfront_distribution" "web_app_distribution" {
  origin {
    domain_name = aws_s3_bucket.web_app.bucket_regional_domain_name
    origin_id = local.s3_origin_id
  }

  default_root_object = "index.html"
  enabled = "true"
  is_ipv6_enabled = "true"
  wait_for_deployment = "false"
  aliases = [aws_s3_bucket.web_app.id]
  price_class = "PriceClass_100" // Only in EU and North America

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress = "true"
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = "false"

      cookies {
        forward = "none"
      }
    }

    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.main_certificate.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  tags = local.tags
}