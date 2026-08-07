# `%{else if}` chained directive. The shim may desugar chains into
# nested `else`/`if` blocks; Menhir might treat "else if" as a syntax
# error or parse it as `else` + content.
x = "%{if var.a}A%{else if var.b}B%{endif}"
y = "%{if var.a}A%{else if var.b}B%{else}C%{endif}"
