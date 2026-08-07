output "test_null" {
  value = data.null.x.id
}

output "test_true" {
  value = var.true
}

output "test_false" {
  value = local.false.name
}

output "test_for" {
  value = module.for.out
}

output "test_in" {
  value = data.in.x.id
}

output "test_if" {
  value = local.if.name
}
