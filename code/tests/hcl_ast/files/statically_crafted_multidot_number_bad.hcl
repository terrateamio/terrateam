# `1.2.3` — Menhir rejects with ATTR_ACCESS_IDENT_EXPECTED; shim
# tokenizes `1.2.3` as one NumberLit and cty.ParseNumberVal fails.
# Different errors on the same input.
x = 1.2.3
