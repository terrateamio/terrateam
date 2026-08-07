# Newline after `.` in attribute traversal. Menhir's grammar allows
# `NEWLINE*` between DOT and attr_identifier (inside `expr_term` or
# `expr_term_paren_access`). The shim's parseExpressionTraversals
# reads the token right after `.` and requires TokenIdent/TokenNumber/
# TokenStar, rejecting TokenNewline.
x = foo.
  bar
