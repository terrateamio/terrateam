-- Delete those plans that are old unless they have changes.  This is because if
-- a plan does not have changes, it is considered applied, so we need those
-- plans to stick around forever.  This should probably be moved somewhere else.
delete from plans as gtp
using work_manifests as gwm
where gtp.work_manifest = gwm.id and gwm.created_at < now() - interval '14 days' and gtp.has_changes
