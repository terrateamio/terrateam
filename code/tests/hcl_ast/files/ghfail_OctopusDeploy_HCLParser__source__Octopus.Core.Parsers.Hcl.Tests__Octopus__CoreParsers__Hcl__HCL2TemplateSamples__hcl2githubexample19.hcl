# Enable shield on Route53 hosted zone
resource "aws_shield_protection" "route53_covidportal" {
  name         = "route53_covidportal"
  resource_arn = "arn:aws:route53:::hostedzone/${aws_route53_zone.covidportal.zone_id}"
}

# Enable shield on ALBs
resource "aws_shield_protection" "alb_covidportal" {
  name         = "alb_covidportal"
  resource_arn = aws_lb.covidportal.arn
}