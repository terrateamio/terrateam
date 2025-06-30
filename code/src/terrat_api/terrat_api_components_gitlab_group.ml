type t = {
  id : int;
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
