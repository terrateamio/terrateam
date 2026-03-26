module Status = struct
  let t_of_yojson = function
    | `String "failed" -> Ok `Failed
    | `String "finished" -> Ok `Finished
    | `String "started" -> Ok `Started
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Failed -> `String "failed"
    | `Finished -> `String "finished"
    | `Started -> `String "started"

  type t =
    ([ `Failed
     | `Finished
     | `Started
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  batch_number : int option; [@default None]
  error : string option; [@default None]
  objects_count : int option; [@default None]
  status : Status.t option; [@default None]
  updated_at : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
