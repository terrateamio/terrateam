# `{for: 1}` — same issue as `{for = 1}` but with colon separator.
# Menhir's `obj_k` used to allow FOR, so this parsed as a regular object.
# Shim's parseObjectCons peeks `for` and enters for-expression
# parsing, which fails because the input isn't valid for-syntax.
x = {for: 1}
