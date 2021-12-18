alter table github_pull_requests
    add column merged_at timestamp with time zone;

update github_pull_requests set merged_at = now() where state = 'merged';

alter table github_pull_requests
    drop constraint github_pull_requests_check,
    add constraint github_pull_requests_check check
        ((state = 'merged' and merged_sha is not null and merged_at is not null)
        or state <> 'merged');
