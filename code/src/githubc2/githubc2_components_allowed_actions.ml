let t_of_yojson = function
  | `String "all" -> Ok `All
  | `String "local_only" -> Ok `Local_only
  | `String "selected" -> Ok `Selected
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `All -> `String "all"
  | `Local_only -> `String "local_only"
  | `Selected -> `String "selected"

type t =
  ([ `All
   | `Local_only
   | `Selected
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
