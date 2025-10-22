create table if not exists pull_request_stacks (
    pull_request uuid primary key,
    stacks jsonb not null
);
