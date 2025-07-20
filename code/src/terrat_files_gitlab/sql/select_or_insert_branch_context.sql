with
inserted as (
  insert into job_contexts (repo, params)
  select
      grm.core_id as repo,
      jsonb_build_object('branch', $branch)
  from gitlab_repositories_map as grm
  where grm.repository_id = $repo_id
  limit 1
  on conflict (repo, (params->>'branch'))
    where (params->>'dest_branch') is null
    do nothing
  returning *
),
row as (
  select id, created_at, updated_at from inserted

  union all

  select id, created_at, updated_at from job_contexts as jc
  inner join gitlab_repositories_map as grm
    on grm.core_id = jc.repo
  where not exists (select 1 from inserted)
        and grm.repository_id = $repo_id
        and (params->>'branch') = $branch
        and (params->>'dest_branch') is null
  limit 1
)
select
    id,
    to_char(created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')
from row
