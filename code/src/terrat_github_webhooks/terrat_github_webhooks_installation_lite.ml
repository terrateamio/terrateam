type t = {
  id : int;
  node_id : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
