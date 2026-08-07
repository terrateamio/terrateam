# Empty `%{}` directive brace. Shim rejects (no directive keyword);
# Menhir's classifier returns None and keeps as literal.
x = "pre %{} post"
