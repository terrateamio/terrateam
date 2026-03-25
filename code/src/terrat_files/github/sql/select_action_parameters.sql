select
    gwm.installation_id,
    gwm.repo_owner,
    gwm.repo_name,
    (case
     when gawm.work_manifest is not null then gawm.branch
     when gdwm.work_manifest is not null then gdwm.branch
     when giwm.work_manifest is not null then giwm.branch
     when gpr.state = 'merged' then gpr.base_branch
     else gpr.branch
     end),
     gwm.sha,
     gwm.pull_number,
     gwm.run_kind,
     gwm.run_type
from github_work_manifests as gwm
left join drift_work_manifests as gdwm
    on gwm.id = gdwm.work_manifest
left join adhoc_work_manifests as gawm
    on gawm.work_manifest = gwm.id
left join github_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
left join index_work_manifests as giwm
    on giwm.work_manifest = gwm.id
where gwm.id = $work_manifest
