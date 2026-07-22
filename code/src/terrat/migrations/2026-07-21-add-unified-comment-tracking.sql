create table if not exists github_unified_comments(
    -- the id github gave us, null until the first unified comment is posted
    comment_id bigint,
    repository bigint not null,
    pull_number bigint not null,
    dirty bigint not null default 0,
    created_at timestamptz not null default current_timestamp,
    foreign key (repository, pull_number) references github_pull_requests (repository, pull_number),
    primary key (repository, pull_number)
);

-- Supports looking up a dirspace's step outputs without scanning every row of
-- a work manifest.
create index if not exists workflow_step_outputs_dirspace_idx
    on workflow_step_outputs (work_manifest, (scope->>'dir'), (scope->>'workspace'))
    where scope->>'type' = 'dirspace';
