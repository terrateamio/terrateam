type t = {
  enabled : bool; [@default false]
  max_workspaces_per_batch : int; [@default 1]
}
[@@deriving yojson { strict = true; meta = true }, make, show, eq]
