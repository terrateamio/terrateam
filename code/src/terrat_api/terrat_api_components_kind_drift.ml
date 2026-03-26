let t_of_yojson = function
  | `String "drift" -> Ok `Drift
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Drift -> `String "drift"

type t = ([ `Drift ][@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
