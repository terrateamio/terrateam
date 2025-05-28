create view github_pull_request_latest_unlocks as
    select
        repository,
        pull_number,
        max(unlocked_at) as unlocked_at
    from github_pull_request_unlocks
    group by repository, pull_number;

create view github_drift_latest_unlocks as
    select
        repository,
        max(unlocked_at) as unlocked_at
    from github_drift_unlocks
    group by repository;

create index github_installations_map_core_id_idx
       on github_installations_map using hash (core_id);

create index github_repositories_map_core_id_idx
       on github_repositories_map using hash (core_id);

create index github_pull_requests_map_core_id_idx
       on github_pull_requests_map using hash (core_id);

create index work_manifests_repo_created_at_idx
       on work_manifests (repo, state, created_at, run_kind)
       include (id, base_sha, sha, run_type);

create index work_manifests_pull_request_created_at_idx
       on work_manifests (pull_request, state, created_at, run_kind)
       include (id, base_sha, sha, run_type);

create index change_dirspaces_repo_shas_idx
       on change_dirspaces (repo, base_sha, sha)
       include (path, workspace, lock_policy);
