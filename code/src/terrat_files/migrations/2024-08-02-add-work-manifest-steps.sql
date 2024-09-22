insert into github_work_manifest_run_types values ('index');


create table if not exists github_work_manifest_steps (
       work_manifest_id uuid not null,
       name text not null,
       created_at timestamp with time zone not null default now(),
       primary key (work_manifest_id, name),
       foreign key (work_manifest_id) references github_work_manifests (id),
       foreign key (name) references github_work_manifest_run_types (id)
);
