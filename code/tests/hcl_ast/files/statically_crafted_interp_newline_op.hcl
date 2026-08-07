# Newline between an operator and its operands inside an interpolation.
# Shim's ParseExpression pushes PushIncludeNewlines(false) inside `${}`
# so the newline is skipped; Menhir's `parse_expr_string` reuses the
# top-level grammar where NEWLINE is significant, so operators followed
# by a newline reject.
x = "p ${1 +
  2} s"
y = "p ${var.a
  == var.b} s"
z = "p ${var.c ? 1
  : 0} s"
