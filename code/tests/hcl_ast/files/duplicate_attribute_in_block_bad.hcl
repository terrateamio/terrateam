# Regression guard: the duplicate-attribute check must apply to block bodies,
# not only the top-level body. Complements duplicate_attribute_bad.hcl, which
# only exercises the top-level case.
resource "x" "y" {
  foo = 1
  foo = 2
}
