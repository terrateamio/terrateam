let t_of_yojson = function
  | `String "collaborators_only" -> Ok `Collaborators_only
  | `String "contributors_only" -> Ok `Contributors_only
  | `String "existing_users" -> Ok `Existing_users
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Collaborators_only -> `String "collaborators_only"
  | `Contributors_only -> `String "contributors_only"
  | `Existing_users -> `String "existing_users"

type t =
  ([ `Collaborators_only
   | `Contributors_only
   | `Existing_users
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
