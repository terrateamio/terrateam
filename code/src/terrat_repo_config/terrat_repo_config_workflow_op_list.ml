module Items = struct
  type t =
    | Workflow_op_init of Terrat_repo_config_workflow_op_init.t
    | Workflow_op_plan of Terrat_repo_config_workflow_op_plan.t
    | Workflow_op_apply of Terrat_repo_config_workflow_op_apply.t
    | Hook_op_run of Terrat_repo_config_hook_op_run.t
    | Hook_op_slack of Terrat_repo_config_hook_op_slack.t
    | Hook_op_env of Terrat_repo_config_hook_op_env.t
  [@@deriving show]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
      [
        (fun v ->
          map (fun v -> Workflow_op_init v) (Terrat_repo_config_workflow_op_init.of_yojson v));
        (fun v ->
          map (fun v -> Workflow_op_plan v) (Terrat_repo_config_workflow_op_plan.of_yojson v));
        (fun v ->
          map (fun v -> Workflow_op_apply v) (Terrat_repo_config_workflow_op_apply.of_yojson v));
        (fun v -> map (fun v -> Hook_op_run v) (Terrat_repo_config_hook_op_run.of_yojson v));
        (fun v -> map (fun v -> Hook_op_slack v) (Terrat_repo_config_hook_op_slack.of_yojson v));
        (fun v -> map (fun v -> Hook_op_env v) (Terrat_repo_config_hook_op_env.of_yojson v));
      ])

  let to_yojson = function
    | Workflow_op_init v -> Terrat_repo_config_workflow_op_init.to_yojson v
    | Workflow_op_plan v -> Terrat_repo_config_workflow_op_plan.to_yojson v
    | Workflow_op_apply v -> Terrat_repo_config_workflow_op_apply.to_yojson v
    | Hook_op_run v -> Terrat_repo_config_hook_op_run.to_yojson v
    | Hook_op_slack v -> Terrat_repo_config_hook_op_slack.to_yojson v
    | Hook_op_env v -> Terrat_repo_config_hook_op_env.to_yojson v
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show]
