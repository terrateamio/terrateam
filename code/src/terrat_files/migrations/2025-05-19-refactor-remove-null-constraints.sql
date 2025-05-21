alter table change_dirspaces
      alter column repo set not null;

alter table code_indexes
      alter column installation set not null;

alter table drift_schedules
      alter column repo set not null;

alter table drift_unlocks
      alter column repo set not null;

alter table gate_approvals
      alter column pull_request set not null;

alter table gates
      alter column pull_request set not null;

alter table pull_request_unlocks
      alter column pull_request set not null;

alter table repo_configs
      alter column installation set not null;

alter table repo_trees
      alter column installation set not null;

alter table work_manifests
      alter column repo set not null;
