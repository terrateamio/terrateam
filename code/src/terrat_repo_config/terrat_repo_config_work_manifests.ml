type t = {
  stale_timeout_sec : int; [@default 86400]
  start_timeout_sec : int; [@default 180]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
