let t_of_yojson = function
  | `String "error" -> Ok `Error
  | `String "outdated" -> Ok `Outdated
  | `String "pending" -> Ok `Pending
  | `String "success" -> Ok `Success
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Error -> `String "error"
  | `Outdated -> `String "outdated"
  | `Pending -> `String "pending"
  | `Success -> `String "success"

type t =
  ([ `Error
   | `Outdated
   | `Pending
   | `Success
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
