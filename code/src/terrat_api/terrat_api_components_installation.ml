type t = {
  id : string;
  name : string;
}
[@@deriving yojson { strict = true; meta = true }, show, eq]
