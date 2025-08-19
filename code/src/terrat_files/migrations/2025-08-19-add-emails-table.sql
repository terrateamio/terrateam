create table github_user_emails (
    created_at timestamp with time zone not null default (now()),
    email text not null,
    username text not null,
    primary key (username, email),
    foreign key (username) references github_users2 (username)
);
