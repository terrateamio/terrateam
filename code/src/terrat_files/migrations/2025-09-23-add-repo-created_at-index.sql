create index concurrently if not exists work_manifests_repo_created_at_state_idx
       on work_manifests (repo, created_at, state, run_kind)
       INCLUDE (id, base_sha, sha, run_type);
