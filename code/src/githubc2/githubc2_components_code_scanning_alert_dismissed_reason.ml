let t_of_yojson = function
  | `String "false positive" -> Ok `False_positive
  | `String "used in tests" -> Ok `Used_in_tests
  | `String "won't fix" -> Ok `Won_t_fix
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `False_positive -> `String "false positive"
  | `Used_in_tests -> `String "used in tests"
  | `Won_t_fix -> `String "won't fix"

type t =
  ([ `False_positive | `Used_in_tests | `Won_t_fix ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  option
[@@deriving yojson { strict = false; meta = true }, show, eq]
