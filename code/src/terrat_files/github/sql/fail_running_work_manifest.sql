update work_manifests as wm
set state = 'aborted', completed_at = now()
from github_installation_repositories as gir
inner join github_work_manifests as gwm
      on gwm.id = wm.id
where gwm.id = wm.id
      and gir.id = gwm.repository
      and gwm.state = 'running'
      and gwm.run_id = $run_id
returning gwm.run_kind, gwm.id, gwm.pull_number, gwm.sha, gwm.run_type
