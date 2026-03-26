module Links_ = struct
  module Primary = struct
    type t = {
      api_url : string option; [@default None]
      web_url : string option; [@default None]
    }
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
end

module Export_status = struct
  let t_of_yojson = function
    | `String "failed" -> Ok `Failed
    | `String "finished" -> Ok `Finished
    | `String "queued" -> Ok `Queued
    | `String "started" -> Ok `Started
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  let t_to_yojson = function
    | `Failed -> `String "failed"
    | `Finished -> `String "finished"
    | `Queued -> `String "queued"
    | `Started -> `String "started"

  type t =
    ([ `Failed
     | `Finished
     | `Queued
     | `Started
     ]
    [@of_yojson t_of_yojson] [@to_yojson t_to_yojson])
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  links_ : Links_.t option; [@default None] [@key "_links"]
  created_at : string option; [@default None]
  description : string option; [@default None]
  export_status : Export_status.t option; [@default None]
  id : int option; [@default None]
  name : string option; [@default None]
  name_with_namespace : string option; [@default None]
  path : string option; [@default None]
  path_with_namespace : string option; [@default None]
}
[@@deriving yojson { strict = false; meta = true }, show, eq]
