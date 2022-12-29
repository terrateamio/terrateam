type t = {
  key : string;
  name : string;
  node_id : string;
  spdx_id : string;
  url : string option;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
