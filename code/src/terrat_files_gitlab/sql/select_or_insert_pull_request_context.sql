with
ins as (
    select $repo_id as repo_id, $pull_number as pull_number
),
inserted as (
  insert into job_contexts (repo, params)
  select
      grm.core_id as repo,
      jsonb_build_object('pull_request', gprm.core_id)
  from ins
  inner join gitlab_repositories_map as grm
      on grm.repository_id = ins.repo_id
  inner join gitlab_pull_requests_map as gprm
      on gprm.repository_id = grm.repository_id
         and gprm.pull_number = ins.pull_number
  on conflict (repo, (params->>'pull_request')) do nothing
  returning *
),
row as (
  select id, created_at, updated_at, params from inserted

  union all

  select id, created_at, updated_at, params from job_contexts as jc
  inner join gitlab_repositories_map as grm
    on grm.core_id = jc.repo
  inner join gitlab_pull_requests_map as gprm
    on grm.repository_id = gprm.repository_id
       and gprm.core_id = (params->>'pull_request')::uuid
  where not exists (select 1 from inserted)
        and grm.repository_id = $repo_id
        and gprm.pull_number = $pull_number
  limit 1
)
select
    id,
    to_char(created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')
from row
