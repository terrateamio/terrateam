insert into work_manifest_run_kinds (id) values ('adhoc');

create table adhoc_work_manifests (
       work_manifest uuid not null,
       branch text not null,
       primary key (work_manifest),
       foreign key (work_manifest) references work_manifests (id)
);
