templates {
  # Simple interpolation
  simple = "Hello, ${var.name}!"

  # Multiple interpolations
  multiple = "${var.first} and ${var.second}"

  # Pure interpolation (unwrapping) - stays as Template since we have literal content
  pure = "${var.value}"

  # Interpolation with expression
  expr = "Result: ${var.a + var.b}"

  # Interpolation with function call
  func = "Upper: ${upper(var.name)}"

  # Interpolation with conditional (using identifier instead of quoted strings)
  cond = "Status: ${var.enabled ? var.yes_text : var.no_text}"

  # Nested attribute access in interpolation
  nested = "Value: ${var.map.key}"

  # Mixed content
  mixed = "prefix-${var.middle}-suffix"

  # Empty string parts
  start_interp = "${var.x}suffix"
  end_interp = "prefix${var.x}"

  # Plain string (no template)
  plain = "just a regular string"

  # Nested expression with index
  indexed = "Item: ${var.list[0]}"

  # Method-like call
  method_like = "Length: ${length(var.items)}"
}
