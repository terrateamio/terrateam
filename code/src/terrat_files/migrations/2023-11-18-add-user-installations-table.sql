create table if not exists github_user_installations (
       user_id uuid not null,
       installation_id bigint not null,
       primary key (user_id, installation_id),
       foreign key (user_id) references users (id),
       foreign key (installation_id) references github_installations (id)
);
