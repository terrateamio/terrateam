create extension if not exists btree_gin;

-- The most recently known hash for a branch.  Useful knowledge for determining
-- if the latest work manifest runs correspond to the latest hash for a branch.
create table branch_commit_hashes (
    branch text not null,
    hash text not null,
    repo uuid not null,
    updated_at timestamp with time zone default (now()) not null,
    primary key (repo, branch)
);

create table job_contexts (
    id uuid default (gen_random_uuid()) primary key,
    repo uuid not null,
    branch text,
    pull_request uuid,
    created_at timestamp with time zone default (now()) not null,
    updated_at timestamp with time zone default (now()) not null
);

create unique index job_contexts_pull_request_idx on job_contexts (id, pull_request);

create table jobs (
    id uuid default (gen_random_uuid()) primary key,
    context_id uuid not null,
    type text not null,
    parameters jsonb not null,
    state text not null,
    initiator text,
    created_at timestamp with time zone default (now()) not null,
    updated_at timestamp with time zone default (now()) not null,
    foreign key (context_id) references job_contexts(id)
);

create index jobs_context_id_idx on jobs (context_id);

create table job_work_manifests (
    job_id uuid,
    work_manifest uuid,
    primary key (job_id, work_manifest),
    foreign key (job_id) references jobs(id),
    foreign key (work_manifest) references work_manifests(id)
);
