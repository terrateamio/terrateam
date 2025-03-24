select
  gir.installation_id,
  gir.id,
  gir.owner,
  gir.name,
  gds.reconcile
from github_work_manifests as gwm
inner join github_drift_work_manifests as gdwm
  on gdwm.work_manifest = gwm.id
inner join github_installation_repositories as gir
  on gir.id = gwm.repository
inner join github_drift_schedules as gds
  on gds.repository = gir.id
where gwm.id = $work_manifest_id
