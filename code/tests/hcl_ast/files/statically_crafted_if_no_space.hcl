# `%{if(cond)}body%{endif}` without a space between `if` and `(`. Shim
# tokenizes `if` as Ident then `(cond)` as a parenthesized expr.
# Menhir's directive classifier only checks `if ` or `if\t`, so this
# falls through to literal.
x = "pre %{if(var.a)}body%{endif} post"
y = "pre %{if (var.a)}other%{endif} post"
