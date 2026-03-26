let t_of_yojson = function
  | `String "open" -> Ok `Open
  | `String "resolved" -> Ok `Resolved
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Open -> `String "open"
  | `Resolved -> `String "resolved"

type t =
  ([ `Open
   | `Resolved
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
