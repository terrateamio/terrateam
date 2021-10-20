create table if not exists installation_feedback (
       created_at timestamp with time zone not null default now(),
       id uuid primary key default gen_random_uuid(),
       installation_id bigint not null,
       msg text not null,
       user_id varchar(256) not null,
       foreign key (installation_id) references github_installations (id),
       foreign key (user_id) references github_users
);
