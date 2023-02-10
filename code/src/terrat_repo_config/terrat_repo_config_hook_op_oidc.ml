type t =
  | Hook_op_oidc_aws of Terrat_repo_config_hook_op_oidc_aws.t
  | Hook_op_oidc_gcp of Terrat_repo_config_hook_op_oidc_gcp.t
[@@deriving show, eq]

let of_yojson =
  Json_schema.one_of
    (let open CCResult in
    [
      (fun v -> map (fun v -> Hook_op_oidc_aws v) (Terrat_repo_config_hook_op_oidc_aws.of_yojson v));
      (fun v -> map (fun v -> Hook_op_oidc_gcp v) (Terrat_repo_config_hook_op_oidc_gcp.of_yojson v));
    ])

let to_yojson = function
  | Hook_op_oidc_aws v -> Terrat_repo_config_hook_op_oidc_aws.to_yojson v
  | Hook_op_oidc_gcp v -> Terrat_repo_config_hook_op_oidc_gcp.to_yojson v
