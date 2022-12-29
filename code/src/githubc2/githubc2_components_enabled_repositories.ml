let t_of_yojson = function
  | `String "all" -> Ok "all"
  | `String "none" -> Ok "none"
  | `String "selected" -> Ok "selected"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
