update schedules set last_run_at = now(), misses = 0 where id = $id
