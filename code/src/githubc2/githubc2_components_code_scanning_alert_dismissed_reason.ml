let t_of_yojson = function
  | `String "false positive" -> Ok "false positive"
  | `String "won't fix" -> Ok "won't fix"
  | `String "used in tests" -> Ok "used in tests"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson]) option
[@@deriving yojson { strict = false; meta = true }, show, eq]
