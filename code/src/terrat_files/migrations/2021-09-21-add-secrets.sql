create table if not exists installation_secrets (
       installation_id bigint not null,
       modified_by varchar(256) not null,
       modified_time timestamp with time zone not null,
       name varchar(256) not null,
       value varchar(4096) not null,
       primary key (installation_id, name),
       foreign key (installation_id) references github_installations (id)
);
