create table if not exists github_installation_states (
       id text primary key
);

insert into github_installation_states values ('installed'), ('uninstalled'), ('suspended');

create table if not exists github_target_types (
       id text primary key
);

insert into github_target_types values ('User'), ('Organization');

create table if not exists github_installations (
       created_at timestamp with time zone not null default now(),
       id bigint primary key,
       login text not null,
       org uuid not null,
       state text not null default 'installed',
       target_type text not null,
       updated_at timestamp with time zone not null default now(),
       foreign key (org) references orgs (id),
       foreign key (state) references github_installation_states (id),
       foreign key (target_type) references github_target_types (id)
);

create table if not exists github_installation_repositories (
       id bigint primary key,
       installation_id bigint not null,
       name text not null,
       owner text not null,
       updated_at timestamp with time zone not null default now(),
       constraint repo_name unique (owner, name),
       foreign key (installation_id) references github_installations (id)
);

create table if not exists github_users (
       expiration timestamp with time zone,
       id text primary key,
       refresh_expiration timestamp with time zone,
       refresh_token text,
       token text not null,
       user_id uuid not null,
       foreign key (user_id) references users (id)
);

create table if not exists github_dirspaces (
       base_sha text not null,
       path text not null,
       repository bigint not null,
       sha text not null,
       workspace text not null,
       primary key (repository, sha, path, workspace),
       foreign key (repository) references github_installation_repositories (id)
);

create table if not exists github_pull_request_states (
       id text primary key
);

insert into github_pull_request_states values
    ('open'),
    ('closed'),
    ('merged');

create table if not exists github_pull_requests (
       base_branch text not null,
       base_sha text not null,
       branch text not null,
       pull_number bigint not null,
       repository bigint not null,
       sha text not null,
       state text not null,
       primary key (repository, pull_number),
       foreign key (repository) references github_installation_repositories (id),
       foreign key (state) references github_pull_request_states (id)
);

create table if not exists github_work_manifest_states (
       id text primary key
);

insert into github_work_manifest_states values
    ('queued'),
    ('running'),
    ('completed'),
    ('aborted');

create table if not exists github_work_manifest_run_types (
       id text primary key
);

insert into github_work_manifest_run_types values ('autoplan'), ('plan'), ('autoapply'), ('apply');

create table if not exists github_work_manifests (
       base_sha text not null,
       completed_at timestamp with time zone,
       created_at timestamp with time zone not null default now(),
       id uuid primary key default gen_random_uuid(),
       pull_number bigint not null,
       repository bigint not null,
       run_id text,
       run_type text not null,
       sha text not null,
       state text not null default 'queued',
       tag_query text not null,
       foreign key (repository) references github_installation_repositories (id),
       foreign key (repository, pull_number) references github_pull_requests (repository, pull_number),
       foreign key (run_type) references github_work_manifest_run_types (id),
       foreign key (state) references github_work_manifest_states (id),
       check (state in ('queued', 'running')
              or (state = 'completed' and run_id is not null and completed_at is not null)
              or (state = 'aborted' and completed_at is not null))
);

create table github_work_manifest_dirspaceflows (
       path text not null,
       work_manifest uuid not null,
       workflow_idx smallint,
       workspace text not null,
       primary key (path, workspace, work_manifest),
       foreign key (work_manifest) references github_work_manifests (id)
);

create index if not exists github_work_manifest_dirspaceflows_work_manifest_idx
    on github_work_manifest_dirspaceflows using hash (work_manifest);

create table if not exists github_terraform_plans (
       data bytea not null,
       path text not null,
       plan_text text not null,
       work_manifest uuid not null,
       workspace text not null,
       primary key (work_manifest, path, workspace),
       foreign key (work_manifest) references github_work_manifests (id)
);

create table if not exists github_work_manifest_results (
       path text not null,
       success boolean not null,
       work_manifest uuid not null,
       workspace text not null,
       primary key (work_manifest, path, workspace),
       foreign key (work_manifest) references github_work_manifests (id)
);
