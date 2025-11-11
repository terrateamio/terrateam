let t_of_yojson = function
  | `String "kv_store_system_read" -> Ok "kv_store_system_read"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
