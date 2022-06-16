module Pull_requests = struct
  module Items = struct
    module Base = struct
      type t = {
        ref_ : string; [@key "ref"]
        repo : Terrat_github_webhooks_repo_ref.t;
        sha : string;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show]
    end

    module Head = struct
      type t = {
        ref_ : string; [@key "ref"]
        repo : Terrat_github_webhooks_repo_ref.t;
        sha : string;
      }
      [@@deriving yojson { strict = false; meta = true }, make, show]
    end

    type t = {
      base : Base.t;
      head : Head.t;
      id : float;
      number : float;
      url : string;
    }
    [@@deriving yojson { strict = false; meta = true }, make, show]
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

module Referenced_workflows = struct
  module Items = struct
    include Json_schema.Additional_properties.Make (Json_schema.Empty_obj) (Json_schema.Obj)
  end

  type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  actor : Terrat_github_webhooks_user.t;
  artifacts_url : string;
  cancel_url : string;
  check_suite_id : int;
  check_suite_node_id : string;
  check_suite_url : string;
  conclusion : string option;
  created_at : string;
  event : string;
  head_branch : string;
  head_commit : Terrat_github_webhooks_commit_simple.t;
  head_repository : Terrat_github_webhooks_repository_lite.t;
  head_sha : string;
  html_url : string;
  id : int;
  jobs_url : string;
  logs_url : string;
  name : string;
  node_id : string;
  path : string option; [@default None]
  previous_attempt_url : string option; [@default None]
  pull_requests : Pull_requests.t;
  referenced_workflows : Referenced_workflows.t option; [@default None]
  repository : Terrat_github_webhooks_repository_lite.t;
  rerun_url : string;
  run_attempt : int;
  run_number : int;
  run_started_at : string;
  status : string;
  triggering_actor : Terrat_github_webhooks_user.t;
  updated_at : string;
  url : string;
  workflow_id : int;
  workflow_url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
