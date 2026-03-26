let t_of_yojson = function
  | `String "kv_store_read" -> Ok `Kv_store_read
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Kv_store_read -> `String "kv_store_read"

type t = ([ `Kv_store_read ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
