# HCL2 does not reserve `for`, `in`, `if` as global identifiers — they're
# keywords only in specific syntactic positions. The shim should accept
# them as plain identifiers in expression positions; Menhir's lexer
# always tokenizes them as FOR/IN/IF, so expressions using them bare
# should reject.
x = in
y = if
z = for
