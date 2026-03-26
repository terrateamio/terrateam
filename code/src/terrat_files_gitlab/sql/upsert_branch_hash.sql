insert into branch_commit_hashes (repo, branch, hash, updated_at)
select
  grm.core_id,
  $branch,
  $hash,
  now()
from gitlab_repositories_map as grm
where grm.repository_id = $repo_id
on conflict (repo, branch) do update set
  hash = excluded.hash,
  updated_at = excluded.updated_at
where branch_commit_hashes.hash <> excluded.hash
