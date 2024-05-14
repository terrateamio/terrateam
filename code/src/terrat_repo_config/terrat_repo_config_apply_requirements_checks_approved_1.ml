type t = {
  count : int; [@default 1]
  enabled : bool; [@default false]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
