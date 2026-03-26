let t_of_yojson = function
  | `String "apply_failed" -> Ok `Apply_failed
  | `String "apply_pending" -> Ok `Apply_pending
  | `String "apply_ready" -> Ok `Apply_ready
  | `String "apply_success" -> Ok `Apply_success
  | `String "no_changes" -> Ok `No_changes
  | `String "plan_failed" -> Ok `Plan_failed
  | `String "plan_pending" -> Ok `Plan_pending
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Apply_failed -> `String "apply_failed"
  | `Apply_pending -> `String "apply_pending"
  | `Apply_ready -> `String "apply_ready"
  | `Apply_success -> `String "apply_success"
  | `No_changes -> `String "no_changes"
  | `Plan_failed -> `String "plan_failed"
  | `Plan_pending -> `String "plan_pending"

type t =
  ([ `Apply_failed
   | `Apply_pending
   | `Apply_ready
   | `Apply_success
   | `No_changes
   | `Plan_failed
   | `Plan_pending
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
