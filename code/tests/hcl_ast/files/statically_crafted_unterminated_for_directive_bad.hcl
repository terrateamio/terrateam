# `%{for}` without a matching `%{endfor}`. Both the shim and Menhir reject:
# the for directive is missing its corresponding endfor directive.
a = "pre %{for x in [1, 2]}body"
