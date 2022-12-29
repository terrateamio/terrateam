let t_of_yojson = function
  | `String "development" -> Ok "development"
  | `String "runtime" -> Ok "runtime"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson]) option
[@@deriving yojson { strict = false; meta = true }, show, eq]
