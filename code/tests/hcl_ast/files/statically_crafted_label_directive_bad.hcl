# Block label containing a template directive. Shim rejects; Menhir
# keeps the raw `%{...}` bytes.
module "mod" "label%{if v}_on%{endif}" {}
