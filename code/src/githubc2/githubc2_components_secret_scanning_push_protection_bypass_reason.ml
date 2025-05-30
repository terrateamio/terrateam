let t_of_yojson = function
  | `String "false_positive" -> Ok "false_positive"
  | `String "used_in_tests" -> Ok "used_in_tests"
  | `String "will_fix_later" -> Ok "will_fix_later"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
