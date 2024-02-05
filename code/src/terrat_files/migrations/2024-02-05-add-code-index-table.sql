create table github_code_index (
       sha text not null,
       installation_id bigint not null,
       index jsonb not null,
       primary key (installation_id, sha),
       foreign key (installation_id) references github_installations(id)
);
