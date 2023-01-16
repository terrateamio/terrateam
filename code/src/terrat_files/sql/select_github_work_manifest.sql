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
    gpr.base_branch,
    gir.installation_id,
    gir.owner,
    gir.name,
    gpr.base_branch
from github_work_manifests as gwm
inner join github_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
inner join github_installation_repositories as gir
    on gir.id = gpr.repository
where gwm.id = $id and gwm.sha = $sha
