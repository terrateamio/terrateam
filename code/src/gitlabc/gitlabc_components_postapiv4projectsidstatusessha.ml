module Primary = struct
  module State = struct
    let t_of_yojson = function
      | `String "pending" -> Ok "pending"
      | `String "running" -> Ok "running"
      | `String "success" -> Ok "success"
      | `String "failed" -> Ok "failed"
      | `String "canceled" -> Ok "canceled"
      | `String "skipped" -> Ok "skipped"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
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
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
