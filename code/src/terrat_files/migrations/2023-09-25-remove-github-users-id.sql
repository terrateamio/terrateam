drop table github_users;

create table github_users (
    id uuid primary key,
    token text not null,
    expiration timestamp with time zone,
    refresh_token text,
    refresh_expiration timestamp with time zone,
    foreign key (id) references users (id)
);
