# resource "aws_instance" "example" {
#   count = var.create_instance ? 1 : 0
# }

locals {
  workload_identity_config = !var.enable_workload_identity ? [] : var.identity_namespace == null ? [{
    identity_namespace = "${var.project}.svc.id.goog" }] : [{ identity_namespace = var.identity_namespace
  }]
}
