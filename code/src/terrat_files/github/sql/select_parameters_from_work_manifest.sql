select
    gir.installation_id,
    gir.owner,
    gir.name,
    (case gpr.state
     when 'merged' then gpr.base_branch
     else gpr.branch
     end),
    gwm.sha,
    gwm.base_sha,
    gpr.pull_number,
    gwm.run_type,
    gwm.run_id,
    extract(epoch from (coalesce(gwm.completed_at, now()) - gwm.created_at))
from work_manifests as gwm
inner join github_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
inner join github_installation_repositories as gir
    on gwm.repository = gir.id
where gwm.id = $id
