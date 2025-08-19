create table if not exists github_work_manifest_comments(
    -- the original id github gave us
    comment_id bigint not null,
    work_manifest uuid not null,
    dir text not null,
    workspace text not null,
    pull_number bigint not null,
    repository bigint not null,
    unified_run_type text not null,
    created_at timestamptz default current_timestamp,
    foreign key (work_manifest, dir, workspace) references work_manifest_results (work_manifest, path, workspace),
    foreign key (repository, pull_number) references github_pull_requests (repository, pull_number),
    primary key (repository, pull_number, dir, workspace, unified_run_type)
);

create index if not exists github_work_manifest_comment_idx on github_work_manifest_comments(comment_id);
