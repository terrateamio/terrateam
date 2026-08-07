# Shim: \uXXXX is exactly 4 hex digits. Menhir: also 4 hex. But \u with FEWER
# than 4 digits — Menhir's sedlex pattern requires exactly 4; fewer would
# fall through as literal. Shim may reject.
x = "short: \u12"
