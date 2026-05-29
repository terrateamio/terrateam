let t_of_yojson = function
  | `String "code" -> Ok `Code
  | `String "markdown" -> Ok `Markdown
  | `String "raw" -> Ok `Raw
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Code -> `String "code"
  | `Markdown -> `String "markdown"
  | `Raw -> `String "raw"

type t =
  ([ `Code
   | `Markdown
   | `Raw
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
