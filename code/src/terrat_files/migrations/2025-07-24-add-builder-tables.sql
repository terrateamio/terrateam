create table job_contexts (
    id uuid default (gen_random_uuid()) primary key,
    repo uuid,
    branch text,
    pull_request uuid,
    created_at timestamp with time zone default (now()) not null,
    updated_at timestamp with time zone default (now()) not null
);

create unique index job_contexts_pull_request_idx on job_contexts (id, pull_request);

create table jobs (
    completed_at timestamp with time zone,
    context_id uuid not null,
    created_at timestamp with time zone default (now()) not null,
    id uuid default (gen_random_uuid()) primary key,
    initiator text,
    parameters jsonb not null,
    state text not null,
    updated_at timestamp with time zone default (now()) not null,
    foreign key (context_id) references job_contexts(id)
);

create index jobs_context_id_idx on jobs (context_id);

create index jobs_type_idx on jobs ((parameters->>'type'));

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
