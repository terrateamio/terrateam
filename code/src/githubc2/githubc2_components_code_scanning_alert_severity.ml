let t_of_yojson = function
  | `String "critical" -> Ok `Critical
  | `String "error" -> Ok `Error
  | `String "high" -> Ok `High
  | `String "low" -> Ok `Low
  | `String "medium" -> Ok `Medium
  | `String "note" -> Ok `Note
  | `String "warning" -> Ok `Warning
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Critical -> `String "critical"
  | `Error -> `String "error"
  | `High -> `String "high"
  | `Low -> `String "low"
  | `Medium -> `String "medium"
  | `Note -> `String "note"
  | `Warning -> `String "warning"

type t =
  ([ `Critical
   | `Error
   | `High
   | `Low
   | `Medium
   | `Note
   | `Warning
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
