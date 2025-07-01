create index concurrently work_manifests_pull_request_base_sha_sha_idx on work_manifests (pull_request, base_sha, sha);

create index concurrently work_manifests_pull_request_state_run_type_created_at_idx on work_manifests (pull_request, state, run_type, created_at);
