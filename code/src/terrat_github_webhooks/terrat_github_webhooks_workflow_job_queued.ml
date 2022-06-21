module Action = struct
  let t_of_yojson = function
    | `String "queued" -> Ok "queued"
    | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

  type t = (string[@of_yojson t_of_yojson])
  [@@deriving yojson { strict = false; meta = true }, show]
end

module Workflow_job_ = struct
  module Completed_at = struct
    type t = unit [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Conclusion = struct
    type t = unit [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Labels = struct
    type t = string list [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Status = struct
    let t_of_yojson = function
      | `String "queued" -> Ok "queued"
      | json -> Error ("Unknown value: " ^ Yojson.Safe.pretty_to_string json)

    type t = (string[@of_yojson t_of_yojson])
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  module Steps = struct
    type t = Terrat_github_webhooks_workflow_step.t list
    [@@deriving yojson { strict = false; meta = true }, show]
  end

  type t = {
    check_run_url : string;
    completed_at : Completed_at.t;
    conclusion : Conclusion.t;
    head_sha : string;
    html_url : string;
    id : int;
    labels : Labels.t;
    name : string;
    node_id : string;
    run_attempt : int;
    run_id : int;
    run_url : string;
    runner_group_id : int option;
    runner_group_name : string option;
    runner_id : int option;
    runner_name : string option;
    started_at : string;
    status : Status.t;
    steps : Steps.t;
    url : string;
  }
  [@@deriving yojson { strict = false; meta = true }, make, show]
end

type t = {
  action : Action.t;
  installation : Terrat_github_webhooks_installation_lite.t option; [@default None]
  organization : Terrat_github_webhooks_organization.t option; [@default None]
  repository : Terrat_github_webhooks_repository.t;
  sender : Terrat_github_webhooks_user.t;
  workflow_job : Workflow_job_.t;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
