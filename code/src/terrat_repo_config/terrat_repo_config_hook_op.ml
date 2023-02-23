type t =
  | Hook_op_drift_create_issue of Terrat_repo_config_hook_op_drift_create_issue.t
  | Hook_op_env_exec of Terrat_repo_config_hook_op_env_exec.t
  | Hook_op_env_source of Terrat_repo_config_hook_op_env_source.t
  | Hook_op_oidc of Terrat_repo_config_hook_op_oidc.t
  | Hook_op_run of Terrat_repo_config_hook_op_run.t
  | Hook_op_slack of Terrat_repo_config_hook_op_slack.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v ->
        map
          (fun v -> Hook_op_drift_create_issue v)
          (Terrat_repo_config_hook_op_drift_create_issue.of_yojson v));
      (fun v -> map (fun v -> Hook_op_env_exec v) (Terrat_repo_config_hook_op_env_exec.of_yojson v));
      (fun v ->
        map (fun v -> Hook_op_env_source v) (Terrat_repo_config_hook_op_env_source.of_yojson v));
      (fun v -> map (fun v -> Hook_op_oidc v) (Terrat_repo_config_hook_op_oidc.of_yojson v));
      (fun v -> map (fun v -> Hook_op_run v) (Terrat_repo_config_hook_op_run.of_yojson v));
      (fun v -> map (fun v -> Hook_op_slack v) (Terrat_repo_config_hook_op_slack.of_yojson v));
    ])

let to_yojson = function
  | Hook_op_drift_create_issue v -> Terrat_repo_config_hook_op_drift_create_issue.to_yojson v
  | Hook_op_env_exec v -> Terrat_repo_config_hook_op_env_exec.to_yojson v
  | Hook_op_env_source v -> Terrat_repo_config_hook_op_env_source.to_yojson v
  | Hook_op_oidc v -> Terrat_repo_config_hook_op_oidc.to_yojson v
  | Hook_op_run v -> Terrat_repo_config_hook_op_run.to_yojson v
  | Hook_op_slack v -> Terrat_repo_config_hook_op_slack.to_yojson v
