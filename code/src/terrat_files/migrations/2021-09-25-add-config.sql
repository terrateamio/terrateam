create table if not exists installation_config (
       auto_merge_after_apply boolean not null,
       installation_id bigint primary key,
       terragrunt boolean not null,
       updated_at timestamp with time zone not null,
       updated_by varchar(256),
       foreign key (installation_id) references github_installations (id),
       foreign key (updated_by) references github_users (user_id)
);
