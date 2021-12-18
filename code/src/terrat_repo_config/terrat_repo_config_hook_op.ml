type t =
  | Hook_op_run of Terrat_repo_config_hook_op_run.t
  | Hook_op_slack of Terrat_repo_config_hook_op_slack.t
  | Hook_op_env of Terrat_repo_config_hook_op_env.t
[@@deriving show]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v -> map (fun v -> Hook_op_run v) (Terrat_repo_config_hook_op_run.of_yojson v));
      (fun v -> map (fun v -> Hook_op_slack v) (Terrat_repo_config_hook_op_slack.of_yojson v));
      (fun v -> map (fun v -> Hook_op_env v) (Terrat_repo_config_hook_op_env.of_yojson v));
    ])

let to_yojson = function
  | Hook_op_run v -> Terrat_repo_config_hook_op_run.to_yojson v
  | Hook_op_slack v -> Terrat_repo_config_hook_op_slack.to_yojson v
  | Hook_op_env v -> Terrat_repo_config_hook_op_env.to_yojson v
