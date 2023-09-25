let t_of_yojson = function
  | `String "critical" -> Ok "critical"
  | `String "high" -> Ok "high"
  | `String "medium" -> Ok "medium"
  | `String "low" -> Ok "low"
  | `String "warning" -> Ok "warning"
  | `String "note" -> Ok "note"
  | `String "error" -> Ok "error"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
