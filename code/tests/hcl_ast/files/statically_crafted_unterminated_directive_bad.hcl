# `%{if}` without a matching `%{endif}`. Shim rejects with missing
# endif; Menhir may keep as literal.
a = "pre %{if var.a}body"
