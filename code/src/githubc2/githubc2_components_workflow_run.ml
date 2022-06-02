module Primary = struct
  module Pull_requests = struct
    type t = Githubc2_components_pull_request_minimal.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    artifacts_url : string;
    cancel_url : string;
    check_suite_id : int option; [@default None]
    check_suite_node_id : string option; [@default None]
    check_suite_url : string;
    conclusion : string option;
    created_at : string;
    event : string;
    head_branch : string option;
    head_commit : Githubc2_components_nullable_simple_commit.t option;
    head_repository : Githubc2_components_minimal_repository.t;
    head_repository_id : int option; [@default None]
    head_sha : string;
    html_url : string;
    id : int;
    jobs_url : string;
    logs_url : string;
    name : string option; [@default None]
    node_id : string;
    previous_attempt_url : string option; [@default None]
    pull_requests : Pull_requests.t option;
    repository : Githubc2_components_minimal_repository.t;
    rerun_url : string;
    run_attempt : int option; [@default None]
    run_number : int;
    run_started_at : string option; [@default None]
    status : string option;
    updated_at : string;
    url : string;
    workflow_id : int;
    workflow_url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, show]
end

include Json_schema.Additional_properties.Make (Primary) (Json_schema.Obj)
