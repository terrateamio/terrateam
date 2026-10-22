-- The time the dispatcher set the work manifest to running, which is when its
-- action run should start.  The stale check measures the start timeout from
-- this time and not from created_at: a work manifest can wait in the queue for a
-- long time, and that wait is not a failure to start (RFD 2826).
--
-- Nullable: a work manifest that the dispatcher has not started has no dispatch
-- time, and a server that does not know the column never writes it.  A null time
-- is never stale, so a queued work manifest can never be aborted on a guess.
alter table work_manifests add column if not exists dispatched_at timestamp with time zone;

-- The work manifests that are running now get a dispatch time of now, so that
-- the ones that are stuck today are abortable at the next stale check.  Now, and
-- not created_at: created_at is the time the work manifest entered the queue,
-- and the wait in the queue is not a failure to start.  The grace period this
-- gives every one of them is the start timeout, and a work manifest that runs
-- sets run_id at its first poll, well within it.
update work_manifests
set dispatched_at = now()
where state = 'running' and dispatched_at is null;