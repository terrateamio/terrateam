select
    gwm.id as id,
    gwm.base_sha,
    to_char(gwm.completed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
    gwm.sha,
    gwm.run_type,
    gwm.state,
    gwm.tag_query,
    gwm.repository,
    gwm.pull_number,
    coalesce(gpr.base_branch, gdwm.branch),
    gir.owner,
    gir.name,
    (case
     when gdwm.work_manifest is not null then 'drift'
     else ''
     end),
    to_json((select json_agg(json_build_object(
                 'dir', gwmds.path,
                 'workspace', gwmds.workspace,
                 'success', not ((gwmr.success is null and gwm.state = 'aborted') or not gwmr.success)))
     from github_work_manifest_dirspaceflows as gwmds
     left join github_work_manifest_results as gwmr
         on gwmds.work_manifest = gwmr.work_manifest
            and gwmds.path = gwmr.path
            and gwmds.workspace = gwmr.workspace
     where gwmds.work_manifest = gwm.id)) as dirspaces,
   gpr.title,
   gpr.branch,
   gwm.username,
   gwm.run_id
from github_work_manifests as gwm
inner join github_installation_repositories as gir
    on gir.id = gwm.repository
inner join github_user_installations as gui
    on gir.installation_id = gui.installation_id
left join github_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
left join github_drift_work_manifests as gdwm
    on gwm.id = gdwm.work_manifest
where gir.installation_id = $installation_id
      and ($pull_number is null or gwm.pull_number = $pull_number)
      and gui.user_id = $user
