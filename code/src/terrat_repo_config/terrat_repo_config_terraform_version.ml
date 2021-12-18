let t_of_yojson = function
  | `String "0.8.8" -> Ok "0.8.8"
  | `String "0.9.11" -> Ok "0.9.11"
  | `String "0.10.8" -> Ok "0.10.8"
  | `String "0.11.15" -> Ok "0.11.15"
  | `String "0.12.31" -> Ok "0.12.31"
  | `String "0.13.7" -> Ok "0.13.7"
  | `String "0.14.11" -> Ok "0.14.11"
  | `String "0.15.5" -> Ok "0.15.5"
  | `String "1.0.7" -> Ok "1.0.7"
  | `String "1.1.2" -> Ok "1.1.2"
  | `String "latest" -> Ok "latest"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson]) [@@deriving yojson { strict = false; meta = true }, show]
