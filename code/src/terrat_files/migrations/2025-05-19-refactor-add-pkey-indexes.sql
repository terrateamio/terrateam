create unique index concurrently if not exists change_dirspaces_pkey_idx
       on change_dirspaces (repo, base_sha, sha, path, workspace)
       include (lock_policy);

create unique index concurrently if not exists code_indexes_pkey_idx
       on code_indexes (installation, sha);

create unique index concurrently if not exists drift_schedules_pkey_idx
       on drift_schedules (repo, name);

create unique index concurrently if not exists drift_unlocks_pkey_idx
       on drift_unlocks(repo, unlocked_at);

create unique index concurrently if not exists gate_approvals_pkey_idx
       on gate_approvals (pull_request, sha, token, approver);

create unique index concurrently if not exists gates_pkey_idx
       on gates (pull_request, sha, dir, workspace, token);

create unique index concurrently if not exists pull_request_unlocks_pkey_idx
       on pull_request_unlocks (pull_request, unlocked_at);

create unique index concurrently if not exists repo_configs_pkey_idx
       on repo_configs (installation, sha);

create unique index concurrently if not exists repo_trees_pkey_idx
       on repo_trees (installation, sha, path)
       include (changed, id);
