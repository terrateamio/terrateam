# `{for = 1}` — Menhir's obj_k included FOR as `Id "for"`, so this used to
# parse as an object with a "for" key. The shim's parseObjectCons
# detects `for` as the start of a for-expression and errors because
# what follows isn't valid for-syntax.
x = {for = 1}
y = {in = 2}
z = {if = 3}
