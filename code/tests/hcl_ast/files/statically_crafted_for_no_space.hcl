# `%{for(v in xs)}body%{endfor}` — menhir's classifier requires
# literal `for ` or `for\t` prefix. Shim parses the for directive as
# a keyword sequence.
x = "[%{for v in(var.list)}${v},%{endfor}]"
