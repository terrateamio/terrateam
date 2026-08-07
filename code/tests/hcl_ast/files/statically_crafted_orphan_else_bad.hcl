# `%{else}` without a matching `%{if}`. Shim rejects; Menhir keeps
# as literal.
a = "pre %{else}extra%{endif} post"
