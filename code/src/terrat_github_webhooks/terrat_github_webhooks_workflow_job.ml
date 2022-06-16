module Labels = struct
  type t = string list [@@deriving yojson { strict = false; meta = true }, show]
end

module Steps = struct
  type t = Terrat_github_webhooks_workflow_step.t list
  [@@deriving yojson { strict = false; meta = true }, show]
end

type t = {
  check_run_url : string;
  completed_at : string option;
  conclusion : string option;
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
  status : string;
  steps : Steps.t;
  url : string;
}
[@@deriving yojson { strict = false; meta = true }, make, show]
