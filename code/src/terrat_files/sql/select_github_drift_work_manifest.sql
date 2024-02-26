select
  gdwm.branch,
  gds.reconcile
from github_drift_work_manifests as gdwm
inner join github_work_manifests as gwm
  on gwm.id = gdwm.work_manifest
inner join github_drift_schedules as gds
  on gds.repository = gwm.repository
where gdwm.work_manifest = $work_manifest
