create table github_workflow_step_outputs (
       created_at timestamp with time zone not null default now(),
       idx smallint not null,
       ignore_errors boolean not null,
       payload jsonb not null,
       scope jsonb not null,
       step text not null,
       success boolean not null,
       work_manifest uuid not null,
       primary key (work_manifest, scope, step, idx),
       foreign key (work_manifest) references github_work_manifests (id)
);
