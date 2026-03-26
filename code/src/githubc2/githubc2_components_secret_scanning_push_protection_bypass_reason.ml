let t_of_yojson = function
  | `String "false_positive" -> Ok `False_positive
  | `String "used_in_tests" -> Ok `Used_in_tests
  | `String "will_fix_later" -> Ok `Will_fix_later
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `False_positive -> `String "false_positive"
  | `Used_in_tests -> `String "used_in_tests"
  | `Will_fix_later -> `String "will_fix_later"

type t =
  ([ `False_positive
   | `Used_in_tests
   | `Will_fix_later
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
