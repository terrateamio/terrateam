type t = {
  id : int;
  username : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
