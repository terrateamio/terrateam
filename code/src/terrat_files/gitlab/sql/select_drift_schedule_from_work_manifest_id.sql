select
  gwm.installation_id,
  gwm.id,
  gwm.repo_owner,
  gwm.repo_name,
  gds.reconcile
from github_work_manifests as gwm
inner join drift_work_manifests as gdwm
  on gdwm.work_manifest = gwm.id
inner join drift_schedules as gds
  on gds.repository = gwm.repository
where gwm.id = $work_manifest_id
