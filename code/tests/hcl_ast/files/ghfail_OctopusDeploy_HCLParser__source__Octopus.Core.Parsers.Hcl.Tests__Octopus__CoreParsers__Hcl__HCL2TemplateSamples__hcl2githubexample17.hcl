###
# Route53 Zone
###

resource "aws_route53_zone" "covidportal" {
  name = var.route53_zone_name

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

###
# Route53 Record - Covid Portal
###

resource "aws_route53_record" "covidportal" {
  zone_id = aws_route53_zone.covidportal.zone_id
  name    = "staging.${aws_route53_zone.covidportal.name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_lb.covidportal.dns_name}"]
}
