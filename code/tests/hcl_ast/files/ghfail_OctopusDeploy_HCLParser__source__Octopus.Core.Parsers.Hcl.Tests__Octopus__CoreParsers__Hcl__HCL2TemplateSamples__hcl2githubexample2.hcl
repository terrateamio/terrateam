resource "aws_acm_certificate" "covidportal_staging" {
  domain_name               = "covid-hcportal.cdssandbox.xyz"
  subject_alternative_names = ["*.covid-hcportal.cdssandbox.xyz"]
  validation_method         = "DNS"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }

  lifecycle {
    create_before_destroy = true
  }
}