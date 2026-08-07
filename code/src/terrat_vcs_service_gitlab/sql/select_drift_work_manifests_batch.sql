select
  dwm.work_manifest,
  dwm.branch
from drift_work_manifests as dwm
inner join gitlab_work_manifests as gwm
  on gwm.id = dwm.work_manifest
where dwm.work_manifest = ANY($ids)
