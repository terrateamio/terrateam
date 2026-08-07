# Function call where the function name is `for`/`in`/`if`. Menhir's
# grammar rule `IDENTIFIER LPAREN fun_args RPAREN` requires IDENTIFIER,
# so keywords reject.
x = for(1)
y = in(2)
z = if(3)
