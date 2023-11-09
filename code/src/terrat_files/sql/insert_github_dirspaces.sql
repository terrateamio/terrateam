insert into github_dirspaces (base_sha, path, repository, sha, workspace, lock_policy)
select * from unnest($base_sha, $path, $repository, $sha, $workspace, $lock_policy) on
conflict (repository, base_sha, sha, path, workspace) do nothing
