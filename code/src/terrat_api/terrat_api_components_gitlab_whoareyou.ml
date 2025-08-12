type t = {
  id : int;
  username : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
