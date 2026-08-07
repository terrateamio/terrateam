resource "a" "b" {
  x = 1

  nested {
    y = 2
  }

  z = 3

  another {
    w = 4
  }
}
