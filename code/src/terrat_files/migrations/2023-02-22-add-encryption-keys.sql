drop table master_encryption_key;

create table if not exists encryption_keys (
       created_at timestamp with time zone not null default now(),
       data bytea not null,
       rank integer primary key
);
