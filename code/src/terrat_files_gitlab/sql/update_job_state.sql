update jobs set
  state = $state,
  completed_at = case when $state = 'completed' then now() else null end
where id = $job
