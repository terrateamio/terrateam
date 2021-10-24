create table if not exists installation_run_ids (
       id smallint primary key,
       installation_id bigint not null unique,
       foreign key (installation_id) references github_installations (id)
);
