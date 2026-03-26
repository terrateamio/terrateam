let t_of_yojson = function
  | `String "aborted" -> Ok `Aborted
  | `String "failure" -> Ok `Failure
  | `String "queued" -> Ok `Queued
  | `String "running" -> Ok `Running
  | `String "success" -> Ok `Success
  | `String "unknown" -> Ok `Unknown
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Aborted -> `String "aborted"
  | `Failure -> `String "failure"
  | `Queued -> `String "queued"
  | `Running -> `String "running"
  | `Success -> `String "success"
  | `Unknown -> `String "unknown"

type t =
  ([ `Aborted
   | `Failure
   | `Queued
   | `Running
   | `Success
   | `Unknown
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
