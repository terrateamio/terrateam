insert into compute_node_work (compute_node, state, work, work_manifest)
values (
  $compute_node_id,
  'created',
  $work,
  $work_manifest
)
on conflict (compute_node, work_manifest) do nothing
