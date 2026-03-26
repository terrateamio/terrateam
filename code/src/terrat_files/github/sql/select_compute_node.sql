select
    id,
    state,
    capabilities,
    to_char(created_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'),
    to_char(updated_at, 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"')
from compute_nodes as cn
where cn.id = $id
for update of cn
