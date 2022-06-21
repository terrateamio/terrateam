type t = {
  color : string;
  default : bool;
  description : string option;
  id : int;
  name : string;
  node_id : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
