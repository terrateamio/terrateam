# Look up the AWS Route 53 zone for the domain names that we are
# generating ACM certificates for.
data "aws_route53_zone" "main" {
  zone_id      = var.aws_route53_zone_id
  private_zone = false
}

# We never create certificates that name subdomains.
# e.g. we never register `subdomain1.subdomain2.example.com`
# Instead, we register a wildcard certificate for
# `*.subdomain2.example.com`.
# This prevents an attacker from using Certificate Transparency
# logs from enumerating subdomains. 
#
# However, we do register root certificates like `example.com`.
locals {
  wildcarded_dns_names = [
    for dns_name in var.dns_names :
    dns_name == data.aws_route53_zone.main.name
    ?
    dns_name
    :
    replace(
      dns_name,
      "/^[a-zA-Z0-9-]+\\./",
      "*."
    )
  ]
}

resource "aws_acm_certificate" "main" {
  domain_name = local.wildcarded_dns_names[0]
  subject_alternative_names = slice(
    local.wildcarded_dns_names,
    1,
    length(local.wildcarded_dns_names),
  )
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "main" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.main : record.fqdn]
}
