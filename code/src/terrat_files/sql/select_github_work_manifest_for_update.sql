select
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
    gwm.run_id
from github_work_manifests as gwm
inner join github_installation_repositories as gir
    on gir.id = gwm.repository
left join github_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
left join github_drift_work_manifests as gdwm
    on gdwm.work_manifest = gwm.id
where gwm.id = $id
for update of gwm
