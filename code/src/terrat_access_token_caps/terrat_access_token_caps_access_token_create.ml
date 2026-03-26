let t_of_yojson = function
  | `String "access_token_create" -> Ok `Access_token_create
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Access_token_create -> `String "access_token_create"

type t = ([ `Access_token_create ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
