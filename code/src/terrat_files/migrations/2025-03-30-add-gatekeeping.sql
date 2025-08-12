create table if not exists github_gates (
       created_at timestamp with time zone not null default now(),
       dir text not null,
       gate jsonb not null,
       pull_number bigint not null,
       repository bigint not null,
       sha text not null,
       token text not null,
       workspace text not null,
       primary key (repository, pull_number, sha, dir, workspace, token),
       foreign key (repository, pull_number) references github_pull_requests (repository, pull_number)
);


create table if not exists github_gate_approvals (
       approver text not null,
       created_at timestamp with time zone not null default now(),
       pull_number bigint not null,
       repository bigint not null,
       sha text not null,
       token text not null,
       primary key (repository, pull_number, sha, token, approver),
       foreign key (repository, pull_number) references github_pull_requests (repository, pull_number)
);
