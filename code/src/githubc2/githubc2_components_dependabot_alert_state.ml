let t_of_yojson = function
  | `String "dismissed" -> Ok "dismissed"
  | `String "fixed" -> Ok "fixed"
  | `String "open" -> Ok "open"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson]) [@@deriving yojson { strict = false; meta = true }, show]