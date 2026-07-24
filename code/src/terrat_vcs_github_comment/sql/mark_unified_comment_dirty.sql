-- Bump the dirty counter of an existing unified comment row.  Unlike the
-- upsert, this never creates a row: only pull requests that already publish a
-- unified comment are refreshed.
update github_unified_comments as guc
set dirty = guc.dirty + 1
from github_work_manifests as gwm
where gwm.id = $work_manifest
  and guc.repository = gwm.repository
  and guc.pull_number = gwm.pull_number
