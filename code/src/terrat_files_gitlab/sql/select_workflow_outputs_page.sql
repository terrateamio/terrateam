with
q as (
  select
      gwso.created_at as created_at,
      gwso.idx as idx,
      gwso.ignore_errors as ignore_errors,
      (case when $lite then null else gwso.payload end) as payload,
      gwso.scope as scope,
      gwso.step as step,
      (case
       when success then 'success'
       else 'failure'
       end) as state
  from workflow_step_outputs as gwso
  inner join gitlab_work_manifests as gwm
      on gwm.id = gwso.work_manifest
  inner join gitlab_user_installations2 as gui
      on gwm.installation_id = gui.installation_id
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
