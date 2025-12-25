select
  to_char(created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
  case
    when jc.params->>'pull_request' is null and jc.params->>'branch' is null then
      jsonb_build_object('type', 'setup')
    when jc.params->>'pull_request' is not null then
      jsonb_build_object('pull_request', gprm.pull_number)
    else
      jc.params
  end,
  to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')
from job_contexts as jc
left join github_pull_requests_map as gprm
  on gprm.core_id = (jc.params->>'pull_request')::uuid
where jc.id = $id

