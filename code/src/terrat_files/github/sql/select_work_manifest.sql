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
    gwm.installation_id,
    gwm.repo_owner,
    gwm.repo_name,
    gwm.run_kind,
    gwm.username
from github_work_manifests as gwm
left join github_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
left join drift_work_manifests as gdwm
    on gwm.id = gdwm.work_manifest
where gwm.id = $id and gwm.sha = $sha and (gpr.pull_number is not null or gdwm.work_manifest is not null)
