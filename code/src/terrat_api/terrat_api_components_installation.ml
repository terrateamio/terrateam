type t = {
  id : string;
  name : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
