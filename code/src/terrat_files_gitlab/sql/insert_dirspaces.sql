insert into change_dirspaces (base_sha, path, sha, workspace, lock_policy, branch_target, repo)
select
        x.base_sha,
        x.path,
        x.sha,
        x.workspace,
        x.lock_policy,
        grm.core_id
from unnest($base_sha, $path, $repository, $sha, $workspace, $lock_policy, $branch_target) as
     x(base_sha, path, repository, sha, workspace, lock_policy, branch_target)
inner join gitlab_repositories_map as grm
      on grm.repository_id = x.repository
on conflict on constraint change_dirspaces_pkey do nothing
