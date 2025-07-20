select
    id,
    context_id,
    params,
    state,
    initiator,
    to_char(created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    to_char(completed_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')
from jobs
inner join job_work_manifests as jwm
    on jwm.job_id = jobs.id
where jwm.work_manifest = $work_manifest
for update of jobs
