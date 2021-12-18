type t = {
  delete_branch : bool; [@default false]
  enabled : bool; [@default false]
}
[@@deriving yojson { strict = true; meta = true }, make, show]
