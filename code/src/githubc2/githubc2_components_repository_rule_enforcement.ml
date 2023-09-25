let t_of_yojson = function
  | `String "disabled" -> Ok "disabled"
  | `String "active" -> Ok "active"
  | `String "evaluate" -> Ok "evaluate"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
