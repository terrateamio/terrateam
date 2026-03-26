let t_of_yojson = function
  | `String "always" -> Ok `Always
  | `String "failure" -> Ok `Failure
  | `String "success" -> Ok `Success
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Always -> `String "always"
  | `Failure -> `String "failure"
  | `Success -> `String "success"

type t =
  ([ `Always
   | `Failure
   | `Success
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
