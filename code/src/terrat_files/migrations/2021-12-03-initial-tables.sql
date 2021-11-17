create table if not exists master_encryption_key (
       rank smallint primary key,
       name text not null
);

create table if not exists orgs (
       id uuid primary key default gen_random_uuid(),
       name text,
);

create table if not exists github_installations (
       access_tokens_url text not null,
       created_at timestamp with time zone not null,
       id bigint primary key,
       name text not null,
       org uuid not null,
       target_type text not null,
       updated_at timestamp with time zone not null,
       foreign key (org) references orgs (id)
);

create table if not exists users (
       avatar_url text,
       email text,
       id uuid primary key default gen_random_uuid(),
       name text,
       org uuid not null,
       receive_marketing_emails boolean not null true,
       foreign key (org) references orgs (id)
);

create table if not exists user_sessions (
       token uuid primary key,
       user_id varchar(256) not null,
       foreign key (user_id) references users (id)
);

create table if not exists github_users (
       expiration timestamp with time zone,
       id text primary key,
       refresh_expiration timestamp with time zone,
       refresh_token timestamp with time zone,
       token text not null,
       user_id uuid not null,
       foreign key (user_id) references users (id)
);

create table if not exists repos (
       id uuid primary key default gen_random_uuid(),
       locked_at timestamp with time zone,
       name text,
       org uuid not null,
       token text not null,
       managed boolean not null default false,
       foreign key (org) references orgs (id)
);

create table if not exists github_repos (
       id text primary key,
       name text not null,
       repo uuid not null,
       url text not null,
       installation_id bigint not null,
       foreign key (installation_id) references github_installations (id),
       foreign key (repo) references repos (id)
);

create table if not exists repo_configs (
       repo uuid primary key,
       config json not null,
       foreign key (repo) references repos (id)
);

create table if not exists repo_dir_states (
       dir_path text not null,
       locked_at timestamp with time zone,
       repo uuid not null,
       primary key (repo, dir_path),
       foreign key (repo) references repos (id)
);

create table if not exists state_prefixes (
       created_at timestamp with time zone not null,
       updated_at timestamp with time zone not null,
       repo uuid not null,
       state_prefix text not null,
       primary key (repo, state_prefix),
       foreign key repo references repos (id)
);

create table if not exists state_files (
       created_at timestamp with time zone not null,
       encryption_key text,
       state_prefix text not null,
       state_suffix text not null,
       storage_path text not null unique,
       primary key (state_prefix, state_suffix, storage_path),
       foreign key (repo) references repos (id)
);

create table if not exists curr_state_files (
       locked_at timestamp with time zone,
       state_prefix text not null,
       state_suffix text not null,
       storage_path text not null unique,
       updated_at timestamp with time zone not null,
       primary key (state_prefix, state_suffix),
       foreign key state_prefix references state_prefixes (state_prefix),
       foreign key (state_prefix, state_suffix, storage_path)
           references state_files (state_prefox, state_suffix, storage_path)
);

create table if not exists pull_request_states (
       id text primary key
);

insert into pull_request_states values ('open'), ('closed'), ('merged');

create table if not exists pull_request_types (
       id text primary key
);

insert into pull_request_types values ('config'), ('key_rotation'), ('state_migration'), ('terraform');

create table if not exists pull_requests (
       created_at timestamp with time zone not null,
       id uuid primary key default gen_random_uuid(),
       real_id text not null,
       repo uuid not null,
       updated_at timestamp with time zone not null,
       state text not null,
       type text not null,
       unique(repo, real_id),
       foreign key (repo) references repos (id),
       foreign key (state) references pull_request_states (id),
       foreign key (type) references pull_request_types (id)
);

create table if not exists github_pull_requests (
       id integer not null,
       repo text not null,
       primary key (repo, id),
       foreign key (repo) references github_repos (id),
       foreign key (installation_id) references github_installations (id)
);
