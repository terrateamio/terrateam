output "test_double_not" {
  value = !!var.x
}

output "test_double_neg" {
  value = --42
}

output "test_not_neg" {
  value = !-var.x
}

output "test_neg_not" {
  value = -!var.x
}
