module State = struct
  let t_of_yojson = function
    | `String "canceled" -> Ok `Canceled
    | `String "failed" -> Ok `Failed
    | `String "pending" -> Ok `Pending
    | `String "running" -> Ok `Running
    | `String "skipped" -> Ok `Skipped
    | `String "success" -> Ok `Success
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Canceled -> `String "canceled"
    | `Failed -> `String "failed"
    | `Pending -> `String "pending"
    | `Running -> `String "running"
    | `Skipped -> `String "skipped"
    | `Success -> `String "success"

  type t =
    ([ `Canceled
     | `Failed
     | `Pending
     | `Running
     | `Skipped
     | `Success
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  context : string; [@default "default"]
  coverage : float option; [@default None]
  description : string option; [@default None]
  name : string; [@default "default"]
  pipeline_id : int option; [@default None]
  ref_ : string option; [@default None] [@key "ref"]
  state : State.t;
  target_url : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
