select
  to_char(created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
  case
    when jc.branch is not null then
      json_build_object(
        'type', 'branch',
        'branch', jc.branch
      )
    when gprm.pull_number is not null then
      json_build_object(
        'type', 'pull_request',
        'pull_request_id', gprm.pull_number
      )
    else
      json_build_object(
        'type', 'setup'
      )
  end,
  to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')
from job_contexts as jc
left join github_pull_requests_map as gprm
  on gprm.core_id = jc.pull_request
where jc.id = $id
