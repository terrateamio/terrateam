select
  gdwm.branch,
  coalesce(gds.reconcile, false)
from drift_work_manifests as gdwm
inner join work_manifests as gwm
  on gwm.id = gdwm.work_manifest
left join drift_schedules as gds
  on gds.repository = gwm.repository
where gdwm.work_manifest = $work_manifest
