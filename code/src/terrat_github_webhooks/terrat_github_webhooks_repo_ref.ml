type t = {
  id : int;
  name : string;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
