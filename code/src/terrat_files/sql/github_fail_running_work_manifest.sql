update github_work_manifests as gwm
set state = 'aborted', completed_at = now()
from github_installation_repositories as gir
where gir.id = gwm.repository
      and gwm.state = 'running'
      and gir.owner = $owner
      and gir.name = $name
      and gwm.run_id = $run_id
returning gwm.id, gwm.pull_number, gwm.sha, gwm.run_type
