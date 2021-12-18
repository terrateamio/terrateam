create table if not exists master_encryption_key (
       rank smallint primary key,
       name text not null
);

create table if not exists orgs (
       active boolean not null default true,
       created_at timestamp with time zone not null default now(),
       id uuid primary key default gen_random_uuid(),
       name text not null
);

create table if not exists users (
       avatar_url text,
       email text,
       id uuid primary key default gen_random_uuid(),
       name text,
       org uuid not null,
       receive_marketing_emails boolean not null default true,
       foreign key (org) references orgs (id)
);

create table if not exists user_sessions (
       token uuid primary key,
       user_id uuid not null,
       foreign key (user_id) references users (id)
);
