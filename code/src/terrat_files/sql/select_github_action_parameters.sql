select
    gir.installation_id,
    gir.owner,
    gir.name,
    (case
     when gdwm.work_manifest is not null then gdwm.branch
     when giwm.work_manifest is not null then giwm.branch
     when gpr.state = 'merged' then gpr.base_branch
     else gpr.branch
     end),
     gwm.sha,
     gwm.pull_number,
     gwm.run_type
from github_work_manifests as gwm
inner join github_installation_repositories as gir
    on gir.id = gwm.repository
left join github_drift_work_manifests as gdwm
    on gwm.id = gdwm.work_manifest
left join github_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
left join github_index_work_manifests as giwm
    on giwm.work_manifest = gwm.id
where gwm.id = $work_manifest
