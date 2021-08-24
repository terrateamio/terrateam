set transaction isolation level repeatable read;

alter table user_sessions
      add column created_at timestamp with time zone not null default now(),
      add column user_agent varchar(256) not null default 'Unknown';

alter table user_sessions
      alter column user_agent drop default;
