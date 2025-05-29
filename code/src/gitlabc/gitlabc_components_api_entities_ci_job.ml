module Primary = struct
  module Artifacts = struct
    type t = Gitlabc_components_api_entities_ci_jobartifact.t list
    [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  module Project = struct
    module Primary = struct
      type t = { ci_job_token_scope_enabled : string option [@default None] }
      [@@deriving yojson { strict = false; meta = true }, show, eq]
    end

    include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
  end

  module Tag_list = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
  end

  type t = {
    allow_failure : bool option; [@default None]
    archived : bool option; [@default None]
    artifacts : Artifacts.t option; [@default None]
    artifacts_expire_at : string option; [@default None]
    artifacts_file : Gitlabc_components_api_entities_ci_jobartifactfile.t option; [@default None]
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
    project : Project.t option; [@default None]
    queued_duration : float option; [@default None]
    ref_ : string option; [@default None] [@key "ref"]
    runner : Gitlabc_components_api_entities_ci_runner.t option; [@default None]
    runner_manager : Gitlabc_components_api_entities_ci_runnermanager.t option; [@default None]
    stage : string option; [@default None]
    started_at : string option; [@default None]
    status : string option; [@default None]
    tag : bool option; [@default None]
    tag_list : Tag_list.t option; [@default None]
    user : Gitlabc_components_api_entities_user.t option; [@default None]
    web_url : string option; [@default None]
  }
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
