select
    gwm.installation_id,
    gwm.repo_owner,
    gwm.repo_name,
    (case
     when gdwm.work_manifest is not null then gdwm.branch
     when giwm.work_manifest is not null then giwm.branch
     when gpr.state = 'merged' then gpr.base_branch
     else gpr.branch
     end),
     gwm.sha,
     gwm.pull_number,
     gwm.run_kind,
     gwm.run_type
from gitlab_work_manifests as gwm
left join drift_work_manifests as gdwm
    on gwm.id = gdwm.work_manifest
left join gitlab_pull_requests as gpr
    on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
left join index_work_manifests as giwm
    on giwm.work_manifest = gwm.id
where gwm.id = $work_manifest
