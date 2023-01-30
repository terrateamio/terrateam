update github_work_manifests set
       run_id = $run_id
from github_work_manifests as gwm
inner join github_installation_repositories as gir
    on gwm.repository = gir.id
left join github_pull_requests as gpr
    on gir.id = gpr.repository and gwm.pull_number = gpr.pull_number
left join github_drift_work_manifests as gdwm
    on gdwm.work_manifest = gwm.id
where github_work_manifests.id = gwm.id
      and (gwm.pull_number is not null or gdwm.work_manifest is not null)
      and gwm.id = $id
      and gwm.sha = $sha
      and gwm.state = 'running'
returning
    gwm.base_sha,
    to_char(gwm.completed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    gwm.sha,
    gwm.run_type,
    gwm.state,
    gwm.tag_query,
    gwm.repository,
    gwm.pull_number,
    coalesce(gpr.base_branch, gdwm.branch),
    gir.installation_id,
    gir.owner,
    gir.name,
    extract(epoch from (now() - gwm.created_at))
