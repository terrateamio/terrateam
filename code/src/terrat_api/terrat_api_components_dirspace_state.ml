let t_of_yojson = function
  | `String "aborted" -> Ok "aborted"
  | `String "failure" -> Ok "failure"
  | `String "queued" -> Ok "queued"
  | `String "running" -> Ok "running"
  | `String "success" -> Ok "success"
  | `String "unknown" -> Ok "unknown"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
