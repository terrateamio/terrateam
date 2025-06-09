delete from flow_states where (now() - updated_at) > interval '1 day'
