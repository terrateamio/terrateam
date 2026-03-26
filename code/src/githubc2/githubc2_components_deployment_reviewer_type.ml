let t_of_yojson = function
  | `String "Team" -> Ok `Team
  | `String "User" -> Ok `User
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Team -> `String "Team"
  | `User -> `String "User"

type t =
  ([ `Team
   | `User
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
