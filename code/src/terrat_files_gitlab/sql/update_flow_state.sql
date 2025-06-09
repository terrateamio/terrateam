insert into flow_states (id, data, updated_at) values($id, $data, now())
on conflict (id) do update set (data, updated_at) = (excluded.data, excluded.updated_at)
