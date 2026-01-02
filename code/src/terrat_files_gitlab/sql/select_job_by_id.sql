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
where jobs.id = $id
for update
