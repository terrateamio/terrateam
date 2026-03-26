let t_of_yojson = function
  | `String "aborted" -> Ok `Aborted
  | `String "completed" -> Ok `Completed
  | `String "queued" -> Ok `Queued
  | `String "running" -> Ok `Running
  | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

let t_to_yojson = function
  | `Aborted -> `String "aborted"
  | `Completed -> `String "completed"
  | `Queued -> `String "queued"
  | `Running -> `String "running"

type t =
  ([ `Aborted
   | `Completed
   | `Queued
   | `Running
   ]
  [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
[@@deriving yojson { strict = false; meta = true }, show, eq]
