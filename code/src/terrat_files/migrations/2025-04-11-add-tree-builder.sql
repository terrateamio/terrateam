create table if not exists github_repo_trees (
  installation_id bigint not null,
  sha text not null,
  created_at timestamp with time zone not null default (now()),
  path text not null,
  changed boolean,
  primary key (installation_id, sha, path),
  foreign key (installation_id) references github_installations (id)
);


insert into github_work_manifest_run_types (id) values ('build-tree');
