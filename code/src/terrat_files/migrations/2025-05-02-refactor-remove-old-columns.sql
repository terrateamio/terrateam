alter table change_dirspaces
      drop column repository,
      drop constraint change_dirspaces_fut_pkey;

alter table code_indexes
      drop column installation_id,
      drop constraint code_indexes_fut_pkey;

alter table drift_schedules
      drop column repository,
      drop constraint drift_schedules_fut_pkey;

alter table drift_unlocks
      drop column repository,
      drop constraint drift_unlocks_fut_pkey;

alter table gate_approvals
      drop column pull_number,
      drop column repository,
      drop constraint gate_approvals_fut_pkey;

alter table gates
      drop column pull_number,
      drop column repository,
      drop constraint gates_fut_pkey;

alter table pull_request_unlocks
      drop column pull_number,
      drop column repository,
      drop constraint pull_request_unlocks_fut_pkey;

alter table repo_configs
      drop column installation_id,
      drop constraint repo_configs_fut_pkey;

alter table repo_trees
      drop column installation_id,
      drop constraint repo_trees_fut_pkey;

alter table work_manifests
      drop column pull_number,
      drop column repository;

