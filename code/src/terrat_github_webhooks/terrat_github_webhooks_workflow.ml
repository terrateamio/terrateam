type t = {
  badge_url : string;
  created_at : string;
  html_url : string;
  id : int;
  name : string;
  node_id : string;
  path : string;
  state : string;
  updated_at : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
