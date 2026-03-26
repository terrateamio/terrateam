let t_of_yojson = function
  | `String "canceled" -> Ok `Canceled
  | `String "failed" -> Ok `Failed
  | `String "in_progress" -> Ok `In_progress
  | `String "pending" -> Ok `Pending
  | `String "succeeded" -> Ok `Succeeded
  | `String "timed_out" -> Ok `Timed_out
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Canceled -> `String "canceled"
  | `Failed -> `String "failed"
  | `In_progress -> `String "in_progress"
  | `Pending -> `String "pending"
  | `Succeeded -> `String "succeeded"
  | `Timed_out -> `String "timed_out"

type t =
  ([ `Canceled
   | `Failed
   | `In_progress
   | `Pending
   | `Succeeded
   | `Timed_out
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
