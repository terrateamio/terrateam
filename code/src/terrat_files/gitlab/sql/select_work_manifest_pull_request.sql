select
    gpr.base_branch,
    gpr.base_sha,
    gpr.branch,
    gpr.sha,
    gpr.pull_number,
    gpr.state,
    gpr.merged_sha,
    to_char(gpr.merged_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as merged_at,
    gpr.title,
    gpr.username
from github_pull_requests as gpr
inner join github_work_manifests as gwm
   on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
where gwm.id = $id
