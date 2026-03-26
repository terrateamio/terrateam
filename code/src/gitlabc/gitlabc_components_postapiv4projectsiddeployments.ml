module Status = struct
  let t_of_yojson = function
    | `String "canceled" -> Ok `Canceled
    | `String "failed" -> Ok `Failed
    | `String "running" -> Ok `Running
    | `String "success" -> Ok `Success
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Canceled -> `String "canceled"
    | `Failed -> `String "failed"
    | `Running -> `String "running"
    | `Success -> `String "success"

  type t =
    ([ `Canceled
     | `Failed
     | `Running
     | `Success
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  environment : string;
  ref_ : string; [@key "ref"]
  sha : string;
  status : Status.t;
  tag : bool;
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
