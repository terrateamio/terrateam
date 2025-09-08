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
