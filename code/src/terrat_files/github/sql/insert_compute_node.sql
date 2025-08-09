insert into compute_node (capabilities, id) values (
    $capabilities,
    $id)
on conflict (id) set updated_at = now()
returning state, created_at, updated_at
