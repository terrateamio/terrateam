let t_of_yojson = function
  | `String "dismissed" -> Ok `Dismissed
  | `String "open" -> Ok `Open
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Dismissed -> `String "dismissed"
  | `Open -> `String "open"

type t =
  ([ `Dismissed
   | `Open
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
