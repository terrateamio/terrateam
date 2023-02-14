create table if not exists github_drift_unlocks (
       repository bigint not null,
       unlocked_at timestamp with time zone not null default now(),
       primary key (repository, unlocked_at),
       foreign key (repository) references github_installation_repositories (id)
);
