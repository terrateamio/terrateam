let t_of_yojson = function
  | `String "existing_users" -> Ok "existing_users"
  | `String "contributors_only" -> Ok "contributors_only"
  | `String "collaborators_only" -> Ok "collaborators_only"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
