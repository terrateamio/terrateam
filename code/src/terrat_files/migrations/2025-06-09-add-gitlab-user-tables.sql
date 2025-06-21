create table if not exists gitlab_users2 (
    avatar_url text,
    created_at timestamp with time zone not null default (now()),
    email text,
    expiration timestamp with time zone,
    gitlab_user_id bigint not null,
    name text,
    refresh_expiration timestamp with time zone,
    refresh_token text,
    token text not null,
    user_id uuid not null unique,
    username text not null primary key,
    foreign key (user_id) references users2 (id)
);
