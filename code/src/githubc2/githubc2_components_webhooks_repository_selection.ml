let t_of_yojson = function
  | `String "all" -> Ok `All
  | `String "selected" -> Ok `Selected
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `All -> `String "all"
  | `Selected -> `String "selected"

type t =
  ([ `All
   | `Selected
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
