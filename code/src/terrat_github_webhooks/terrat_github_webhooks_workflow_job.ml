module Labels = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show, eq]
end

module Steps = struct
  type t = Terrat_github_webhooks_workflow_step.t list
  [@@deriving yojson { strict = false; meta = true }, show, eq]
end

type t = {
  check_run_url : string;
  completed_at : string option; [@default None]
  conclusion : string option; [@default None]
  head_sha : string;
  html_url : string;
  id : int;
  labels : Labels.t;
  name : string;
  node_id : string;
  run_attempt : int;
  run_id : int;
  run_url : string;
  runner_group_id : int option; [@default None]
  runner_group_name : string option; [@default None]
  runner_id : int option; [@default None]
  runner_name : string option; [@default None]
  started_at : string;
  status : string;
  steps : Steps.t;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show, eq]
