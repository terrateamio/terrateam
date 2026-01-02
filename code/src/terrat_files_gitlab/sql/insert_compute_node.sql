insert into compute_nodes (capabilities, id) values (
    $capabilities,
    $id)
on conflict (id) do update
set updated_at = now()
returning state, created_at, updated_at
