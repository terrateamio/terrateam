# Namespaced name without a following `(`. Menhir's lexer captures
# `foo::bar` as a single IDENTIFIER, producing `Id "foo::bar"`. The
# shim's parseExpressionTerm interprets `TokenDoubleColon` as an
# indicator of a function call and requires `()`, rejecting this form.
x = foo::bar
y = core::max + 1
z = a::b::c
