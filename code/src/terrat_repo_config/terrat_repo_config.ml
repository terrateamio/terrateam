module Access_control = Terrat_repo_config_access_control
module Access_control_match_list = Terrat_repo_config_access_control_match_list
module Access_control_policy = Terrat_repo_config_access_control_policy
module Apply_requirements = Terrat_repo_config_apply_requirements
module Apply_requirements_checks = Terrat_repo_config_apply_requirements_checks
module Apply_requirements_checks_1 = Terrat_repo_config_apply_requirements_checks_1
module Apply_requirements_checks_2 = Terrat_repo_config_apply_requirements_checks_2

module Apply_requirements_checks_apply_after_merge =
  Terrat_repo_config_apply_requirements_checks_apply_after_merge

module Apply_requirements_checks_approved = Terrat_repo_config_apply_requirements_checks_approved

module Apply_requirements_checks_approved_1 =
  Terrat_repo_config_apply_requirements_checks_approved_1

module Apply_requirements_checks_approved_2 =
  Terrat_repo_config_apply_requirements_checks_approved_2

module Apply_requirements_checks_merge_conflicts =
  Terrat_repo_config_apply_requirements_checks_merge_conflicts

module Apply_requirements_checks_status_checks =
  Terrat_repo_config_apply_requirements_checks_status_checks

module Automerge = Terrat_repo_config_automerge
module Batch_runs = Terrat_repo_config_batch_runs
module Config_builder = Terrat_repo_config_config_builder
module Custom_tags = Terrat_repo_config_custom_tags
module Custom_tags_branch = Terrat_repo_config_custom_tags_branch
module Destination_branch_name = Terrat_repo_config_destination_branch_name
module Destination_branch_object = Terrat_repo_config_destination_branch_object
module Dir = Terrat_repo_config_dir
module Drift_1 = Terrat_repo_config_drift_1
module Drift_2 = Terrat_repo_config_drift_2
module Drift_schedule = Terrat_repo_config_drift_schedule
module Engine = Terrat_repo_config_engine
module Engine_cdktf = Terrat_repo_config_engine_cdktf
module Engine_custom = Terrat_repo_config_engine_custom
module Engine_fly = Terrat_repo_config_engine_fly
module Engine_opentofu = Terrat_repo_config_engine_opentofu
module Engine_other = Terrat_repo_config_engine_other
module Engine_pulumi = Terrat_repo_config_engine_pulumi
module Engine_terraform = Terrat_repo_config_engine_terraform
module Engine_terragrunt = Terrat_repo_config_engine_terragrunt
module Gate = Terrat_repo_config_gate
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
module Runs_on = Terrat_repo_config_runs_on
module Stack_config = Terrat_repo_config_stack_config
module Stacks = Terrat_repo_config_stacks
module Storage_plan_cmd = Terrat_repo_config_storage_plan_cmd
module Storage_plan_s3 = Terrat_repo_config_storage_plan_s3
module Storage_plan_terrateam = Terrat_repo_config_storage_plan_terrateam
module Tags = Terrat_repo_config_tags
module Terraform_version = Terrat_repo_config_terraform_version
module Tree_builder = Terrat_repo_config_tree_builder
module Version_1 = Terrat_repo_config_version_1
module When_modified = Terrat_repo_config_when_modified
module When_modified_nullable = Terrat_repo_config_when_modified_nullable
module Workflow_entry = Terrat_repo_config_workflow_entry
module Workflow_op_apply = Terrat_repo_config_workflow_op_apply
module Workflow_op_checkov = Terrat_repo_config_workflow_op_checkov
module Workflow_op_conftest = Terrat_repo_config_workflow_op_conftest
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
