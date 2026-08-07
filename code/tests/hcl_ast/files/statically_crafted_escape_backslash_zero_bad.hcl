# Shim: rejects \0 as invalid escape sequence.
# Menhir: accepts any \X via the lexer's fall-through "\\' + any" rule.
x = "null char: \0 in here"
