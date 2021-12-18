select
    gir.installation_id,
    gir.owner,
    gir.name,
    (case gpr.state
     when 'merged' then gpr.base_branch
     else gpr.branch
     end),
     gwm.sha,
     gwm.pull_number,
     gwm.run_type
from github_work_manifests as gwm
inner join github_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
inner join github_installation_repositories as gir
    on gir.id = gpr.repository
where gwm.id = $work_manifest
