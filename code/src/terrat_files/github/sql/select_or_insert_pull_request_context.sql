with
ins as (
    select $repo_id as repo_id, $pull_number as pull_number
)
insert into job_contexts (repo, pull_request)
select
    grm.core_id as repo,
    gprm.core_id as pull_request
from ins
left join github_repositories_map as grm
    on grm.repository_id = ins.repo_id
left join github_pull_requests_map as gprm
    on gprm.repository_id = grm.repository_id
       and gprm.pull_number = ins.pull_number
limit 1
on conflict (id, pull_request) do nothing
returning
    id,
    to_char(created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    (pull_request is null)
