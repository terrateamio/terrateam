ellipsis_complex {
  # Ellipsis in function call
  merged = concat(var.list1, var.list2...)

  # Ellipsis with expression
  expanded = concat([1, 2], var.items...)

  # Multiple args before ellipsis
  result = merge(local.defaults, var.overrides...)

  # Ellipsis in for object (grouping)
  grouped = {for item in var.items : item.key => item.value...}

  # Ellipsis with complex expression
  flattened = concat([], [for x in var.nested : x]...)

  # Multi-line function call with variadic last arg: NEWLINE* absorbed around
  # the ellipsis and before the closing paren.
  multiline_fn_variadic = concat(
    var.list1,
    var.list2...
  )

  # Multi-line for-object grouping: NEWLINE* absorbed after the ellipsis
  # before the closing brace.
  multiline_for_object = {
    for k, v in var.m : k => v...
  }

  # Ellipsis applied to a parenthesized expression (conditional).
  paren_ellipsis = concat([], (var.cond ? var.a : var.b)...)

  # For-object grouping followed by a collection_if.
  grouped_if = {for x in var.items : x.key => x.value... if x.active}
}
