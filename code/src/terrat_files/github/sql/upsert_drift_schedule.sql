insert into drift_schedules as gds
  (schedule, reconcile, tag_query, updated_at, name, window_start, window_end, repo)
select
        $schedule,
        $reconcile,
        $tag_query,
        now(),
        $name,
        $window_start,
        $window_end,
        grm.core_id
from github_repositories_map as grm
where grm.repository_id = $repo
on conflict on constraint drift_schedules_pkey
do update set
  (schedule,
   reconcile,
   tag_query,
   updated_at,
   name,
   window_start,
   window_end) =
     (excluded.schedule,
      excluded.reconcile,
      excluded.tag_query,
      excluded.updated_at,
      excluded.name,
      excluded.window_start,
      excluded.window_end)
where
  (gds.schedule, gds.reconcile, gds.tag_query, gds.name, gds.window_start, gds.window_end) <> (excluded.schedule, excluded.reconcile, excluded.tag_query, excluded.name, excluded.window_start, excluded.window_end)
