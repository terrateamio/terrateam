let t_of_yojson = function
  | `String "dismissed" -> Ok `Dismissed
  | `String "fixed" -> Ok `Fixed
  | `String "open" -> Ok `Open
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Dismissed -> `String "dismissed"
  | `Fixed -> `String "fixed"
  | `Open -> `String "open"

type t = ([ `Dismissed | `Fixed | `Open ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson]) option
[@@deriving yojson { strict = false; meta = true }, show, eq]
