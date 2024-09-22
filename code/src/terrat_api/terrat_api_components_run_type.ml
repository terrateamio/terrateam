let t_of_yojson = function
  | `String "apply" -> Ok "apply"
  | `String "build-config" -> Ok "build-config"
  | `String "index" -> Ok "index"
  | `String "plan" -> Ok "plan"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
