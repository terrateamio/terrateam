# String with literal newline inside interpolation argument. Shim's
# scan_string_lit rejects literal newlines in quoted strings; Menhir's
# `parse_template_string` state uses `any` which includes `\n`.
x = "a ${"b
c"} d"
