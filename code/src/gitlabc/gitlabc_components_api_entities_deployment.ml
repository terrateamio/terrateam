module Primary = struct
  type t = {
    created_at : string option; [@default None]
    deployable : Gitlabc_components_api_entities_ci_job.t option; [@default None]
    environment : Gitlabc_components_api_entities_environmentbasic.t option; [@default None]
    id : int option; [@default None]
    iid : int option; [@default None]
    ref_ : string option; [@default None] [@key "ref"]
    sha : string option; [@default None]
    status : string option; [@default None]
    updated_at : string option; [@default None]
    user : Gitlabc_components_api_entities_userbasic.t option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
