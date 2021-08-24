create table if not exists github_users (
       expiration timestamp with time zone,
       refresh_expiration timestamp with time zone,
       refresh_token varchar(1024),
       token varchar(1024) not null,
       user_id varchar(256) primary key
);

create table if not exists user_sessions (
       token uuid primary key,
       user_id varchar(256) not null,
       foreign key (user_id) references github_users
);

create table if not exists github_user_installations (
       github_installation bigint not null,
       user_id varchar(256) not null,
       primary key (user_id, github_installation),
       foreign key (user_id) references github_users,
       foreign key (github_installation) references github_installations (id)
);
