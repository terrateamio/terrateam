create table if not exists github_drift_schedules (
       reconcile boolean not null,
       repository bigint primary key,
       schedule text not null,
       foreign key (repository) references github_installation_repositories (id)
);

create table if not exists github_drift_work_manifests (
       branch text not null,
       work_manifest uuid primary key,
       foreign key (work_manifest) references github_work_manifests (id)
);

alter table github_work_manifests alter pull_number drop not null;
