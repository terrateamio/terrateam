# Function call where the function name is a keyword. Menhir's
# lexer tokenizes `true`/`false`/`null`/`for`/`in`/`if` as their own
# keyword tokens, and only IDENTIFIER can introduce a function call.
# The shim sees all of these as TokenIdent and accepts the call form.
x = true(1)
y = null(2)
z = false()
