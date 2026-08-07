output "test" {
  value = [for group in var.items : group.members...]
}
