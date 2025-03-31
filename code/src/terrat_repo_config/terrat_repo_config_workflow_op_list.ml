module Items = struct
  type t =
    | Workflow_op_init of Terrat_repo_config_workflow_op_init.t
    | Workflow_op_plan of Terrat_repo_config_workflow_op_plan.t
    | Workflow_op_checkov of Terrat_repo_config_workflow_op_checkov.t
    | Workflow_op_conftest of Terrat_repo_config_workflow_op_conftest.t
    | Workflow_op_apply of Terrat_repo_config_workflow_op_apply.t
    | Hook_op_run of Terrat_repo_config_hook_op_run.t
    | Hook_op_slack of Terrat_repo_config_hook_op_slack.t
    | Hook_op_env_exec of Terrat_repo_config_hook_op_env_exec.t
    | Hook_op_env_source of Terrat_repo_config_hook_op_env_source.t
    | Hook_op_oidc of Terrat_repo_config_hook_op_oidc.t
  [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [
         (fun v ->
           map (fun v -> Workflow_op_init v) (Terrat_repo_config_workflow_op_init.of_yojson v));
         (fun v ->
           map (fun v -> Workflow_op_plan v) (Terrat_repo_config_workflow_op_plan.of_yojson v));
         (fun v ->
           map (fun v -> Workflow_op_checkov v) (Terrat_repo_config_workflow_op_checkov.of_yojson v));
         (fun v ->
           map
             (fun v -> Workflow_op_conftest v)
             (Terrat_repo_config_workflow_op_conftest.of_yojson v));
         (fun v ->
           map (fun v -> Workflow_op_apply v) (Terrat_repo_config_workflow_op_apply.of_yojson v));
         (fun v -> map (fun v -> Hook_op_run v) (Terrat_repo_config_hook_op_run.of_yojson v));
         (fun v -> map (fun v -> Hook_op_slack v) (Terrat_repo_config_hook_op_slack.of_yojson v));
         (fun v ->
           map (fun v -> Hook_op_env_exec v) (Terrat_repo_config_hook_op_env_exec.of_yojson v));
         (fun v ->
           map (fun v -> Hook_op_env_source v) (Terrat_repo_config_hook_op_env_source.of_yojson v));
         (fun v -> map (fun v -> Hook_op_oidc v) (Terrat_repo_config_hook_op_oidc.of_yojson v));
       ])

  let to_yojson = function
    | Workflow_op_init v -> Terrat_repo_config_workflow_op_init.to_yojson v
    | Workflow_op_plan v -> Terrat_repo_config_workflow_op_plan.to_yojson v
    | Workflow_op_checkov v -> Terrat_repo_config_workflow_op_checkov.to_yojson v
    | Workflow_op_conftest v -> Terrat_repo_config_workflow_op_conftest.to_yojson v
    | Workflow_op_apply v -> Terrat_repo_config_workflow_op_apply.to_yojson v
    | Hook_op_run v -> Terrat_repo_config_hook_op_run.to_yojson v
    | Hook_op_slack v -> Terrat_repo_config_hook_op_slack.to_yojson v
    | Hook_op_env_exec v -> Terrat_repo_config_hook_op_env_exec.to_yojson v
    | Hook_op_env_source v -> Terrat_repo_config_hook_op_env_source.to_yojson v
    | Hook_op_oidc v -> Terrat_repo_config_hook_op_oidc.to_yojson v
end

type t = Items.t list [@@deriving yojson { strict = false; meta = true }, show, eq]
