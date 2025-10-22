let t_of_yojson = function
  | `String "apply_failed" -> Ok "apply_failed"
  | `String "apply_pending" -> Ok "apply_pending"
  | `String "apply_ready" -> Ok "apply_ready"
  | `String "apply_success" -> Ok "apply_success"
  | `String "no_changes" -> Ok "no_changes"
  | `String "plan_failed" -> Ok "plan_failed"
  | `String "plan_pending" -> Ok "plan_pending"
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

type t = (string[@of_yojson t_of_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
