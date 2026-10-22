-- The dispatch time is the first time the work manifest goes running.  The
-- runner sets the state again when it polls for the first time, and that must
-- not move the start timeout of the stale check (RFD 2826).
update work_manifests
set state = 'running', dispatched_at = coalesce(dispatched_at, now())
where id = $id
