module Access_control = Terrat_repo_config_access_control
module Access_control_match_list = Terrat_repo_config_access_control_match_list
module Access_control_policy = Terrat_repo_config_access_control_policy
module Automerge = Terrat_repo_config_automerge
module Custom_tags = Terrat_repo_config_custom_tags
module Custom_tags_branch = Terrat_repo_config_custom_tags_branch
module Destination_branch_name = Terrat_repo_config_destination_branch_name
module Destination_branch_object = Terrat_repo_config_destination_branch_object
module Dir = Terrat_repo_config_dir
module Drift = Terrat_repo_config_drift
module Engine = Terrat_repo_config_engine
module Engine_cdktf = Terrat_repo_config_engine_cdktf
module Engine_opentofu = Terrat_repo_config_engine_opentofu
module Engine_terraform = Terrat_repo_config_engine_terraform
module Engine_terragrunt = Terrat_repo_config_engine_terragrunt
module Hook = Terrat_repo_config_hook
module Hook_list = Terrat_repo_config_hook_list
module Hook_op = Terrat_repo_config_hook_op
module Hook_op_drift_create_issue = Terrat_repo_config_hook_op_drift_create_issue
module Hook_op_env_exec = Terrat_repo_config_hook_op_env_exec
module Hook_op_env_source = Terrat_repo_config_hook_op_env_source
module Hook_op_oidc = Terrat_repo_config_hook_op_oidc
module Hook_op_oidc_aws = Terrat_repo_config_hook_op_oidc_aws
module Hook_op_oidc_gcp = Terrat_repo_config_hook_op_oidc_gcp
module Hook_op_run = Terrat_repo_config_hook_op_run
module Hook_op_slack = Terrat_repo_config_hook_op_slack
module Integrations = Terrat_repo_config_integrations
module Permission = Terrat_repo_config_permission
module Retry = Terrat_repo_config_retry
module Run_on = Terrat_repo_config_run_on
module Storage_plan_cmd = Terrat_repo_config_storage_plan_cmd
module Storage_plan_s3 = Terrat_repo_config_storage_plan_s3
module Storage_plan_terrateam = Terrat_repo_config_storage_plan_terrateam
module Tags = Terrat_repo_config_tags
module Terraform_version = Terrat_repo_config_terraform_version
module Version_1 = Terrat_repo_config_version_1
module When_modified = Terrat_repo_config_when_modified
module When_modified_nullable = Terrat_repo_config_when_modified_nullable
module Workflow_entry = Terrat_repo_config_workflow_entry
module Workflow_op_apply = Terrat_repo_config_workflow_op_apply
module Workflow_op_init = Terrat_repo_config_workflow_op_init
module Workflow_op_list = Terrat_repo_config_workflow_op_list
module Workflow_op_plan = Terrat_repo_config_workflow_op_plan
module Workspaces = Terrat_repo_config_workspaces

module Event = struct
  type t = Version_1 of Terrat_repo_config_version_1.t [@@deriving show, eq]

  let of_yojson =
    Json_schema.one_of
      (let open CCResult in
       [ (fun v -> map (fun v -> Version_1 v) (Terrat_repo_config_version_1.of_yojson v)) ])

  let to_yojson = function
    | Version_1 v -> Terrat_repo_config_version_1.to_yojson v
end
