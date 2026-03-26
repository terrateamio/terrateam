let t_of_yojson = function
  | `String "active" -> Ok `Active
  | `String "disabled" -> Ok `Disabled
  | `String "evaluate" -> Ok `Evaluate
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Active -> `String "active"
  | `Disabled -> `String "disabled"
  | `Evaluate -> `String "evaluate"

type t =
  ([ `Active
   | `Disabled
   | `Evaluate
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
