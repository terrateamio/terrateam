create table if not exists users2 (
    created_at timestamp with time zone not null default (now()),
    id uuid not null default (gen_random_uuid()) primary key
);

create table if not exists user_sessions2 (
    created_at timestamp with time zone not null default (now()),
    token uuid not null default (gen_random_uuid()) primary key,
    user_agent text,
    user_id uuid not null,
    foreign key (user_id) references users2 (id)
);

create table if not exists github_users2 (
    avatar_url text,
    created_at timestamp with time zone not null default (now()),
    email text,
    expiration timestamp with time zone,
    name text,
    refresh_expiration timestamp with time zone,
    refresh_token text,
    token text not null,
    user_id uuid not null unique,
    username text not null primary key,
    foreign key (user_id) references users2 (id)
);

create table if not exists github_user_installations2 (
    installation_id bigint not null,
    user_id uuid not null,
    primary key (user_id, installation_id),
    foreign key (user_id) references users2 (id),
    foreign key (installation_id) references github_installations (id)
);

create index github_users2_user_id on github_users2 (user_id);
