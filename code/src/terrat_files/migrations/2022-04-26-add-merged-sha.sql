alter table github_pull_requests
    add column merged_sha text;

update github_pull_requests set merged_sha = sha where state = 'merged';

alter table github_pull_requests
    add constraint github_pull_requests_check check
        ((state = 'merged' and merged_sha is not null) or state <> 'merged');
