provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_acm_certificate" "main_certificate" {
  provider = aws.us-east-1
  domain   = "*.isnan.eu"
}

data "aws_route53_zone" "primary" {
  name = "isnan.eu."
}

# Routing to the web client (IPv4)
resource "aws_route53_record" "web_client_ipv4" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "celsus.isnan.eu"
  type    = "A"

  alias {
    zone_id                = aws_cloudfront_distribution.web_app_distribution.hosted_zone_id
    evaluate_target_health = "false"
    name                   = aws_cloudfront_distribution.web_app_distribution.domain_name
  }
}

# Routing to the web client (IPv6)
resource "aws_route53_record" "web_client_ipv6" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "celsus.isnan.eu"
  type    = "AAAA"

  alias {
    zone_id                = aws_cloudfront_distribution.web_app_distribution.hosted_zone_id
    evaluate_target_health = "false"
    name                   = aws_cloudfront_distribution.web_app_distribution.domain_name
  }
}