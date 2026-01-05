select
    gwm.base_sha,
    to_char(gwm.completed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as completed_at,
    to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
    gwm.pull_number,
    gwm.repository,
    gwm.run_id,
    gwm.run_type,
    gwm.sha,
    gwm.state,
    gwm.tag_query,
    gwm.username,
    gwm.run_kind,
    gwm.installation_id,
    gwm.repo_owner,
    gwm.repo_name,
    gwm.environment,
    gwm.runs_on,
    gwm.branch
from github_work_manifests as gwm
where gwm.id = $id
