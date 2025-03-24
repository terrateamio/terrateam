with
work_manifest as (
     select
         gwm.id as id,
         gwm.repository as repository,
         gwm.pull_number as pull_number
     from github_work_manifests as gwm
     where gwm.id = $id and gwm.state = 'running'
),
recent_completed_work_manifest as (
    select
        gwm.run_type as run_type,
        gwmr.success as success,
        gtp.data as data
    from github_work_manifest_results as gwmr
    inner join github_work_manifests as gwm
        on gwm.id = gwmr.work_manifest
    inner join work_manifest as wm
        on wm.repository = gwm.repository
    left join github_drift_work_manifests as gdwm
        on gdwm.work_manifest = gwmr.work_manifest
    left join github_terraform_plans as gtp
        on gtp.work_manifest = gwmr.work_manifest
           and gtp.path = gwmr.path
           and gtp.workspace = gwmr.workspace
    where gwmr.path = $dir
          and gwmr.workspace = $workspace
          and ((wm.pull_number is not null and wm.pull_number = gwm.pull_number)
               or (wm.pull_number is null and gdwm.work_manifest is not null))
          and completed_at is not null
    order by gwm.completed_at desc
    limit 1
)
select encode(data, 'base64') from recent_completed_work_manifest
where data is not null and success and run_type in ('plan', 'autoplan')
