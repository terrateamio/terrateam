alter table change_dirspaces
      add constraint change_dirspaces_fut_pkey unique using index change_dirspaces_pkey_idx;

alter table code_indexes
      add constraint code_indexes_fut_pkey unique using index code_indexes_pkey_idx;

alter table drift_schedules
      add constraint drift_schedules_fut_pkey unique using index drift_schedules_pkey_idx;

alter table drift_unlocks
      add constraint drift_unlocks_fut_pkey unique using index drift_unlocks_pkey_idx;

alter table gate_approvals
      add constraint gate_approvals_fut_pkey unique using index gate_approvals_pkey_idx;

alter table gates
      add constraint gates_fut_pkey unique using index gates_pkey_idx;

alter table pull_request_unlocks
      add constraint pull_request_unlocks_fut_pkey unique using index pull_request_unlocks_pkey_idx;

alter table repo_configs
      add constraint repo_configs_fut_pkey unique using index repo_configs_pkey_idx;

alter table repo_trees
      add constraint repo_trees_fut_pkey unique using index repo_trees_pkey_idx;
