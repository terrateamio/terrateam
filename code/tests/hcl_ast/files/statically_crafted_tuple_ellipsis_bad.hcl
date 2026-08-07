# Ellipsis `...` in tuple position. Menhir's `tuple` grammar has a
# rule `expr_paren ELLIPSIS` that matches a single ellipsis expression
# (typically useful with for-object grouping). Shim's parseTupleCons
# only expects `,` or `]` after each element — ellipsis in a tuple
# position rejects.
x = [a...]
y = [a, b...]
