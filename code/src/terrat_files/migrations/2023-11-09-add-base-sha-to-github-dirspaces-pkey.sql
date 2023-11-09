alter table github_dirspaces drop constraint github_dirspaces_pkey;

alter table github_dirspaces add primary key (repository, base_sha, sha, path, workspace);
