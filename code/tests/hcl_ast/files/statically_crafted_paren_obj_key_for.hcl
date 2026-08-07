# [for] is mode-switching at the start of a [{..}] body (introduces a
# for-object expression), but inside parentheses it should fall back to a
# bare identifier reference — same as [in] / [if]. hclsyntax accepts
# [(for) = "v"] as an object key, but Menhir's [obj_k_expr] reaches a
# state where the [LPAREN FOR ...] lookahead doesn't admit
# [expr_paren -> simple_expr -> FOR], so the case rejects.
a = { (for) = "v" }
b = { k1 = 1, (for) = 2 }
