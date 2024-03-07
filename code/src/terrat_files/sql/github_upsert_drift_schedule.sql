insert into github_drift_schedules as gds
  (repository, schedule, reconcile, tag_query, updated_at)
values ($repo, $schedule, $reconcile, $tag_query, now())
on conflict (repository)
do update set
  (schedule,
   reconcile,
   tag_query,
   updated_at) =
     (excluded.schedule,
      excluded.reconcile,
      excluded.tag_query,
      excluded.updated_at)
where
  (gds.schedule, gds.reconcile, gds.tag_query) <> (excluded.schedule, excluded.reconcile, excluded.tag_query)
