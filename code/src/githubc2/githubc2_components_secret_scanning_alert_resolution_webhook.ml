let t_of_yojson = function
  | `String "false_positive" -> Ok "false_positive"
  | `String "wont_fix" -> Ok "wont_fix"
  | `String "revoked" -> Ok "revoked"
  | `String "used_in_tests" -> Ok "used_in_tests"
  | `String "pattern_deleted" -> Ok "pattern_deleted"
  | `String "pattern_edited" -> Ok "pattern_edited"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson]) option
[@@deriving yojson { strict = false; meta = true }, show, eq]
