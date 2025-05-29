module Primary = struct
  type t = {
    allow_failure : bool option; [@default None]
    author : Gitlabc_components_api_entities_userbasic.t option; [@default None]
    coverage : float option; [@default None]
    created_at : string option; [@default None]
    description : string option; [@default None]
    finished_at : string option; [@default None]
    id : int option; [@default None]
    name : string option; [@default None]
    pipeline_id : int option; [@default None]
    ref_ : string option; [@default None] [@key "ref"]
    sha : string option; [@default None]
    started_at : string option; [@default None]
    status : string option; [@default None]
    target_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
