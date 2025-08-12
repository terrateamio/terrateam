alter table github_pull_requests
    add column all_dirspaces_applied boolean not null default (false),
    add column created_at timestamp with time zone not null default (now());

create index github_pull_requests_repo_applied_idx
    on github_pull_requests (repository, all_dirspaces_applied);

update github_pull_requests
set all_dirspaces_applied = true
where state = 'closed' or (state = 'merged' and merged_at < (now() - interval '3 months'));
