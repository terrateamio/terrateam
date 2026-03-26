update compute_nodes set
    state = $state,
    terminated_at = case when $state = 'terminated' then now() else null end
where id = $compute_node_id
