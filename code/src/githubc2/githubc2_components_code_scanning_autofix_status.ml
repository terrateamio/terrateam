let t_of_yojson = function
  | `String "pending" -> Ok "pending"
  | `String "error" -> Ok "error"
  | `String "success" -> Ok "success"
  | `String "outdated" -> Ok "outdated"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
