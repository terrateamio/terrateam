drop table user_sessions;

create table user_sessions (
       token uuid default gen_random_uuid() primary key,
       user_id uuid not null,
       created_at timestamp with time zone not null default now(),
       user_agent text,
       foreign key (user_id) references users (id)
);

create index user_sessions_user_id_idx
    on user_sessions using hash (user_id);
