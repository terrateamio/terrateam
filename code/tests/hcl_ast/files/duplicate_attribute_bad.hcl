# Regression guard: HCL forbids setting the same attribute more than once per
# body. The Menhir parser used to accept this silently; both parsers must now
# reject it.
foo = 1
foo = 2
