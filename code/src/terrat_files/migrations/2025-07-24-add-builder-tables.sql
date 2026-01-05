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
    params jsonb not null,
    created_at timestamp with time zone default (now()) not null,
    updated_at timestamp with time zone default (now()) not null
);

create index job_contexts_repo_params_idx on job_contexts using gin (repo, params jsonb_path_ops);

-- We want various unique constraints.  We make one for each type of uniqueness
-- we want to ensure.
--
-- This first one is we only one job context per pull request.
create unique index job_contexts_params_unique_pr_idx on job_contexts (
  repo,
  (params->>'pull_request'));

-- Secondly, if we are just running against a branch.
create unique index job_contexts_params_unique_branch_idx on job_contexts (
  repo,
  (params->>'branch'))
  where (params->>'dest_branch') is null;

-- Finally, if we want to run against a branch but only difference relative to a
-- destination branch.
create unique index job_contexts_params_unique_branch_dest_branch_idx on job_contexts (
  repo,
  (params->>'branch'),
  (params->>'dest_branch'));

create table jobs (
    completed_at timestamp with time zone,
    context_id uuid not null,
    created_at timestamp with time zone default (now()) not null,
    id uuid default (gen_random_uuid()) primary key,
    initiator text,
    params jsonb not null,
    state text not null,
    updated_at timestamp with time zone default (now()) not null,
    foreign key (context_id) references job_contexts(id)
);

create index jobs_context_id_created_at_idx on jobs (context_id, created_at);

create index jobs_context_id_type_idx on jobs (context_id, (params->>'type'));

create table job_work_manifests (
    job_id uuid,
    work_manifest uuid,
    primary key (job_id, work_manifest),
    foreign key (job_id) references jobs(id),
    foreign key (work_manifest) references work_manifests(id)
);

create table compute_node_states (
    id text primary key
);

insert into compute_node_states values ('starting'), ('running'), ('terminated');

create table compute_nodes (
    capabilities jsonb not null,
    created_at timestamp with time zone default (now()) not null,
    id uuid primary key,
    state text not null default ('starting'),
    terminated_at timestamp with time zone,
    updated_at timestamp with time zone default (now()) not null,
    foreign key (state) references compute_node_states(id)
);

create table compute_node_work_states (
    id text primary key
);

insert into compute_node_work_states values ('created'), ('completed'), ('aborted');

create table compute_node_work (
    compute_node uuid not null,
    created_at timestamp with time zone default (now()) not null,
    state text not null,
    work jsonb not null,
    work_manifest uuid not null,
    primary key (compute_node, work_manifest),
    foreign key (work_manifest) references work_manifests(id),
    foreign key (compute_node) references compute_nodes(id),
    foreign key (state) references compute_node_work_states(id)
);

-- Ensure that a compute node can only have a single item in created state
create unique index compute_node_work_wm_state_idx
    on compute_node_work (compute_node)
    where state = 'created';

-- Maintain that any aborted work manifests have their corresponding work aborted
create or replace function trigger_update_compute_node_work_state()
returns trigger as $$
begin
    if NEW.state = 'aborted' or NEW.state = 'completed' then
        update compute_node_work set state = NEW.state
        where work_manifest = NEW.id;
    end if;
    return NEW;
end;
$$ language plpgsql;

create trigger work_manifest_compute_node_work_state_trigger
    after insert or update on work_manifests
    for each row
    execute function trigger_update_compute_node_work_state();
