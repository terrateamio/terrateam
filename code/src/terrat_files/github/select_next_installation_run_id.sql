select generate_series($min, $max) as genid except select id from installation_run_ids
order by genid
limit 1
