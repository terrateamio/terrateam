insert into github_work_manifest_run_types values ('build-config');

create table github_repo_configs (
       installation_id bigint not null,
       sha text not null,
       created_at timestamp with time zone not null default (now()),
       data jsonb not null,
       primary key (installation_id, sha),
       foreign key (installation_id) references github_installations (id)
);

create index github_repo_configs_created_at_idx on github_repo_configs (created_at);
