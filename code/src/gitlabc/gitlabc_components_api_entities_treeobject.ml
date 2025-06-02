type t = {
  id : string;
  mode : string;
  name : string;
  path : string;
  type_ : string; [@key "type"]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
