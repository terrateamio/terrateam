module Primary = struct
  type t = {
    allow_failure : bool option; [@default None]
    commit : Gitlabc_components_api_entities_commit.t option; [@default None]
    coverage : float option; [@default None]
    created_at : string option; [@default None]
    duration : float option; [@default None]
    erased_at : string option; [@default None]
    failure_reason : string option; [@default None]
    finished_at : string option; [@default None]
    id : int option; [@default None]
    name : string option; [@default None]
    pipeline : Gitlabc_components_api_entities_ci_pipelinebasic.t option; [@default None]
    project : Gitlabc_components_api_entities_projectidentity.t option; [@default None]
    queued_duration : float option; [@default None]
    ref_ : string option; [@default None] [@key "ref"]
    stage : string option; [@default None]
    started_at : string option; [@default None]
    status : string option; [@default None]
    tag : bool option; [@default None]
    user : Gitlabc_components_api_entities_user.t option; [@default None]
    web_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
