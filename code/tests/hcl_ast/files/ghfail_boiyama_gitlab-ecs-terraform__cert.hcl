# Get CloudFormation
data "template_file" "cloudformation" {
  template = "${file("${path.module}/templates/cert/cloudformation.yml")}"

  vars {
    project = "${var.project}"
    domain  = "${var.domain_name}"
    sans    = "${indent(8, "${join("", formatlist("\n- \"%s%s\"", var.additional_names, var.domain_name))}")}"
  }
}

# Create stack for cert
resource "aws_cloudformation_stack" "cert" {
  depends_on    = ["aws_ses_domain_identity.main"]
  name          = "${var.project}-stack-cert"
  template_body = "${data.template_file.cloudformation.rendered}"
}
