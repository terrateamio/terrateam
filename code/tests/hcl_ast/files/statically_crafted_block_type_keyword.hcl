# Block TYPE being a keyword. Menhir's `block` rule requires IDENTIFIER
# as the block type; TRUE/FALSE/NULL/FOR/IN/IF tokens aren't IDENTIFIER
# and cause rejection. The shim treats these as TokenIdent.
true {
  x = 1
}
null "lbl" {
  y = 2
}
false {
  z = 3
}
