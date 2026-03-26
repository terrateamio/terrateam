let t_of_yojson = function
  | `String "read" -> Ok `Read
  | `String "write" -> Ok `Write
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Read -> `String "read"
  | `Write -> `String "write"

type t =
  ([ `Read
   | `Write
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
