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
    coalesce(gpr.base_branch, gdwm.branch, giwm.branch),
    gwm.installation_id,
    gwm.repo_owner,
    gwm.repo_name,
    gwm.run_id,
    gwm.username,
    gwm.run_kind
from github_work_manifests as gwm
left join github_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
left join drift_work_manifests as gdwm
    on gdwm.work_manifest = gwm.id
left join index_work_manifests as giwm
    on giwm.work_manifest = gwm.id
where gwm.id = $id
for update of gwm
