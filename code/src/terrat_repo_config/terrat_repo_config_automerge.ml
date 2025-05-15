type t = {
  delete_branch : bool; [@default false]
  enabled : bool; [@default false]
  require_explicit_apply : bool; [@default false]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
