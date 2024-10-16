with
q as (
  select
      gwso.created_at as created_at,
      gwso.idx as idx,
      gwso.ignore_errors as ignore_errors,
      gwso.payload as payload,
      gwso.scope as scope,
      gwso.step as step,
      (case
       when success then 'success'
       else 'failure'
       end) as state
  from github_workflow_step_outputs as gwso
  inner join github_work_manifests as gwm
      on gwm.id = gwso.work_manifest
  inner join github_installation_repositories as gir
      on gir.id = gwm.repository
  inner join github_user_installations as gui
      on gir.installation_id = gui.installation_id
  where gui.user_id = $user and gui.installation_id = $installation_id and gwm.id = $work_manifest_id
)
select
    to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
    idx,
    ignore_errors,
    payload,
    scope,
    step,
    state
from q
{{where}}
