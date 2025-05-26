create or replace view github_repo_trees as
       select
        gim.installation_id as installation_id,
        rt.sha as sha,
        rt.created_at as created_at,
        rt.path as path,
        rt.changed as changed,
        rt.id as id
       from repo_trees as rt
       inner join github_installations_map as gim
             on rt.installation = gim.core_id;

alter table change_dirspaces
      drop constraint github_dirspaces_pkey;

alter table change_dirspaces
      alter column repository drop not null;

alter table change_dirspaces
      add primary key (repo, base_sha, sha, path, workspace);

alter table code_indexes
      drop constraint github_code_index_pkey;

alter table code_indexes
      alter column installation_id drop not null;

alter table code_indexes
      add primary key (installation, sha);

alter table drift_schedules
      drop constraint github_drift_schedules_pkey;

alter table drift_schedules
      alter column repository drop not null;

alter table drift_schedules
      add primary key (repo, name);

alter table drift_unlocks
      drop constraint github_drift_unlocks_pkey;

alter table drift_unlocks
      alter column repository drop not null;

alter table drift_unlocks
      add primary key (repo, unlocked_at);

alter table gate_approvals
      drop constraint github_gate_approvals_pkey;

alter table gate_approvals
      alter column pull_number drop not null,
      alter column repository drop not null;

alter table gate_approvals
      add primary key (pull_request, sha, token, approver);

alter table gates
      drop constraint github_gates_pkey;

alter table gates
      alter column pull_number drop not null,
      alter column repository drop not null;

alter table gates
      add primary key (pull_request, sha, dir, workspace, token);

alter table pull_request_unlocks
      drop constraint github_pull_request_unlocks_pkey;

alter table pull_request_unlocks
      alter column pull_number drop not null,
      alter column repository drop not null;

alter table pull_request_unlocks
      add primary key (pull_request, unlocked_at);

alter table repo_configs
      drop constraint github_repo_configs_pkey;

alter table repo_configs
      alter column installation_id drop not null;

alter table repo_configs
      add primary key (installation, sha);

alter table repo_trees
      drop constraint github_repo_trees_pkey;

alter table repo_trees
      alter column installation_id drop not null;

alter table repo_trees
      add primary key (installation, sha, path);

alter table work_manifests
      alter column pull_number drop not null,
      alter column repository drop not null;
