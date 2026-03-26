let t_of_yojson = function
  | `String "false_positive" -> Ok `False_positive
  | `String "pattern_deleted" -> Ok `Pattern_deleted
  | `String "pattern_edited" -> Ok `Pattern_edited
  | `String "revoked" -> Ok `Revoked
  | `String "used_in_tests" -> Ok `Used_in_tests
  | `String "wont_fix" -> Ok `Wont_fix
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `False_positive -> `String "false_positive"
  | `Pattern_deleted -> `String "pattern_deleted"
  | `Pattern_edited -> `String "pattern_edited"
  | `Revoked -> `String "revoked"
  | `Used_in_tests -> `String "used_in_tests"
  | `Wont_fix -> `String "wont_fix"

type t =
  ([ `False_positive | `Pattern_deleted | `Pattern_edited | `Revoked | `Used_in_tests | `Wont_fix ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  option
[@@deriving yojson { strict = false; meta = true }, show, eq]
