-- We only create a single row per pull request
create table if not exists github_pull_request_summary_comments(
    -- the original id github gave us
    comment_id bigint not null,
    pull_number bigint not null,
    repository bigint not null,
    created_at timestamptz default current_timestamp,
    foreign key (repository, pull_number) references github_pull_requests (repository, pull_number),
    primary key (repository, pull_number)
);

create index if not exists github_pull_request_summary_comments_idx on github_pull_request_summary_comments(comment_id);

-- TODO: See if we need to store stats somewhere
-- And then upsert to the "elements" table to derive stats
create table if not exists github_pull_request_tf_summary_elements(
    -- the original id github gave us
    comment_id bigint not null,
    dir text not null,
    workspace text not null,
    work_manifest uuid not null,
    unified_run_type text not null,
    pull_number bigint not null,
    repository bigint not null,
    status text not null constraint valid_status check (status in ('pending', 'created', 'updated', 'deleted')) default 'pending',
    created_at timestamptz default current_timestamp,
    foreign key (work_manifest, dir, workspace) references work_manifest_results (work_manifest, path, workspace),
    foreign key (repository, pull_number) references github_pull_requests (repository, pull_number),
    primary key (repository, pull_number, dir, workspace)
);

create index if not exists github_pull_request_summary_elements_idx on github_pull_request_summary_elements(comment_id);
