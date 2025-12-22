insert into job_contexts (repo, branch)
select
    grm.core_id as repo,
    $branch
from github_repositories_map as grm
where grm.repository_id = $repo_id
limit 1
on conflict (id, branch) do nothing
returning
    id,
    to_char(created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')
