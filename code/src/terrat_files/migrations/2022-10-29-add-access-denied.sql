create table if not exists github_work_manifest_access_control_denied_dirspaces (
       path text not null,
       policy text[],
       work_manifest uuid not null,
       workspace text not null,
       primary key (work_manifest, path, workspace)
);
