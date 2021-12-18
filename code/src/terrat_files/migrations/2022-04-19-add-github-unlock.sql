create table github_pull_request_unlocks (
       pull_number bigint not null,
       repository bigint not null,
       unlocked_at timestamp with time zone not null default now(),
       primary key (repository, pull_number, unlocked_at),
       foreign key (repository, pull_number) references github_pull_requests (repository, pull_number)
);
