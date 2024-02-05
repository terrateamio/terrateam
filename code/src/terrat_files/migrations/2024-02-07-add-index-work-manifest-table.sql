create table github_index_work_manifests (
       work_manifest uuid primary key,
       branch text not null,
       foreign key (work_manifest) references github_work_manifests(id)
);
