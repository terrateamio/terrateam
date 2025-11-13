-- This CTE selects only the dirspaces which 
-- changed in the current work manifest
-- provided by Terrateam's server.
with currently_changed_dirspaces as (
  select
    cd.path as dir,
    cd.workspace
  from change_dirspaces cd
  inner join work_manifests wm on (
        wm.sha = cd.sha
    and wm.base_sha = cd.base_sha
    and wm.repo = cd.repo
  )
  where wm.id = $work_manifest
)
select 
    wm.id,
    gwmc.dir,
    gwmc.workspace,
    wm.run_type,
    wso.ignore_errors,
    wso.payload,
    wso.scope,
    wso.success,
    wso.step
from github_work_manifest_comments gwmc
-- Do not confuse this with the work manifests
-- targeted by the CTE, these ones are from
-- previous runs that may still be relevant to be
-- posted in a comment.
inner join work_manifests wm on gwmc.work_manifest = wm.id
inner join workflow_step_outputs wso on (
        wso.work_manifest = wm.id 
    and wso.scope->>'type' = 'dirspace'
    and gwmc.dir = wso.scope->>'dir' 
    and gwmc.workspace = wso.scope->>'workspace'
)
inner join currently_changed_dirspaces ccd on (
        gwmc.dir = ccd.dir
    and gwmc.workspace = ccd.workspace
)
where 
    gwmc.comment_id = $comment_id
order by wso.idx
