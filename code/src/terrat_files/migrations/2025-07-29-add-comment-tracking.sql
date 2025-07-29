create table if not exists github_work_manifest_comments(
    -- the original id github gave us
    comment_id bigint not null,
    work_manifest uuid not null,
    dir text not null,
    workspace text not null,
    created_at timestamptz default current_timestamp,
    foreign key (work_manifest, dir, workspace) references work_manifest_results (work_manifest, path, workspace),
    primary key (work_manifest, dir, workspace)
);

create index on github_work_manifest_comments(comment_id);
