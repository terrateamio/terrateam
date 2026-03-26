module State = struct
  let t_of_yojson = function
    | `String "aborted" -> Ok `Aborted
    | `String "completed" -> Ok `Completed
    | `String "failed" -> Ok `Failed
    | `String "pending" -> Ok `Pending
    | `String "running" -> Ok `Running
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Aborted -> `String "aborted"
    | `Completed -> `String "completed"
    | `Failed -> `String "failed"
    | `Pending -> `String "pending"
    | `Running -> `String "running"

  type t =
    ([ `Aborted
     | `Completed
     | `Failed
     | `Pending
     | `Running
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  id : string;
  name : string;
  state : State.t;
  updated_at : string;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
