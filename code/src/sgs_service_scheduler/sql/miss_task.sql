-- A trigger with nobody registered to run it: advance the next run so the task re-runs on its own
-- schedule, and count the miss. Returns the miss count; the dispatcher deletes the row at three.
update schedules set last_run_at = now(), misses = misses + 1
where id = $id
returning misses
