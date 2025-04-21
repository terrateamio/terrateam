alter table github_code_index rename to code_indexes;

alter table github_dirspaces rename to change_dirspaces;

alter table github_drift_schedules rename to drift_schedules;

alter table github_drift_unlocks rename to drift_unlocks;

alter table github_drift_work_manifests rename to drift_work_manifests;

alter table github_gate_approvals rename to gate_approvals;

alter table github_gates rename to gates;

alter table github_index_work_manifests rename to index_work_manifests;

alter table github_pull_request_unlocks rename to pull_request_unlocks;

alter table github_repo_configs rename to repo_configs;

alter table github_repo_trees rename to repo_trees;

alter table github_target_types rename to target_types;

alter table github_terraform_plans rename to plans;

alter table github_work_manifest_access_control_denied_dirspaces rename to work_manifest_access_control_denied_dirspaces;

alter table github_work_manifest_dirspaceflows rename to work_manifest_dirspaceflows;

alter table github_work_manifest_results rename to work_manifest_results;

alter table github_work_manifest_run_kinds rename to work_manifest_run_kinds;

alter table github_work_manifest_run_types rename to work_manifest_run_types;

alter table github_work_manifest_states rename to work_manifest_states;

alter table github_work_manifest_steps rename to work_manifest_steps;

alter table github_work_manifests rename to work_manifests;

alter table github_workflow_step_outputs rename to workflow_step_outputs;

create view github_code_index as
  select * from code_indexes;

create view github_dirspaces as
  select * from change_dirspaces;

create view github_drift_schedules as
  select * from drift_schedules;

create view github_drift_unlocks as
  select * from drift_unlocks;

create view github_drift_work_manifests as
  select * from drift_work_manifests;

create view github_gate_approvals as
  select * from gate_approvals;

create view github_gates as
  select * from gates;

create view github_index_work_manifests as
  select * from index_work_manifests;

create view github_pull_request_unlocks as
  select * from pull_request_unlocks;

create view github_repo_configs as
  select * from repo_configs;

create view github_repo_trees as
  select * from repo_trees;

create view github_target_types as
  select * from target_types;

create view github_terraform_plans as
  select * from plans;

create view github_work_manifest_access_control_denied_dirspaces as
  select * from work_manifest_access_control_denied_dirspaces;

create view github_work_manifest_dirspaceflows as
  select * from work_manifest_dirspaceflows;

create view github_work_manifest_results as
  select * from work_manifest_results;

create view github_work_manifest_run_kinds as
  select * from work_manifest_run_kinds;

create view github_work_manifest_run_types as
  select * from work_manifest_run_types;

create view github_work_manifest_states as
  select * from work_manifest_states;

create view github_work_manifest_steps as
  select * from work_manifest_steps;

create view github_work_manifests as
  select * from work_manifests;

create view github_workflow_step_outputs as
  select * from workflow_step_outputs;
