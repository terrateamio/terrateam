# Empty `${}` interpolation. Shim rejects (missing expression);
# Menhir keeps the empty `${}` as literal text.
x = "pre ${} post"
