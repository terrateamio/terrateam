# Namespaced name used as base of a traversal. In menhir this is a
# single IDENTIFIER so `core::max.x` parses as `Attr(Id "core::max", A_string "x")`.
# The shim rejects the `::` form without `(`.
x = core::max.x
y = foo::bar[0]
