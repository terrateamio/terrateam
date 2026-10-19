let t_of_yojson = function
  | `String "always" -> Ok `Always
  | `String "change_or_failure" -> Ok `Change_or_failure
  | `String "failure" -> Ok `Failure
  | `String "never" -> Ok `Never
  | `String "success" -> Ok `Success
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Always -> `String "always"
  | `Change_or_failure -> `String "change_or_failure"
  | `Failure -> `String "failure"
  | `Never -> `String "never"
  | `Success -> `String "success"

type t =
  ([ `Always
   | `Change_or_failure
   | `Failure
   | `Never
   | `Success
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
