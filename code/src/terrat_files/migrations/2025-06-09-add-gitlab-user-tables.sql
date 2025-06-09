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
