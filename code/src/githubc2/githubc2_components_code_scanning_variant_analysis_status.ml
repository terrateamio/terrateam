let t_of_yojson = function
  | `String "pending" -> Ok "pending"
  | `String "in_progress" -> Ok "in_progress"
  | `String "succeeded" -> Ok "succeeded"
  | `String "failed" -> Ok "failed"
  | `String "canceled" -> Ok "canceled"
  | `String "timed_out" -> Ok "timed_out"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
