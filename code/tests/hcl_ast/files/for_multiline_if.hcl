resource "example" "test" {
  filtered = [for x in var.items : x
    if x.enabled
    && x.visible
  ]
}
