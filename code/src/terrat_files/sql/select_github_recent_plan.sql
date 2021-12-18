with
work_manifest as (
     select id, repository, pull_number
     from github_work_manifests as gwm
     where gwm.id = $id and gwm.state = 'running'
),
recent_completed_work_manifest as (
    select
        gwm.id as id,
        gwm.completed_at as completed_at,
        gwm.run_type as run_type,
        gwmr.success as success,
        gtp.data as data
    from github_work_manifests as gwm
    inner join github_work_manifest_results as gwmr on gwm.id = gwmr.work_manifest
    inner join work_manifest as wm on wm.repository = gwm.repository and wm.pull_number = gwm.pull_number
    left join github_terraform_plans as gtp
        on gwm.id = gtp.work_manifest and gtp.path = gwmr.path and gtp.workspace = gwmr.workspace
    where gwmr.path = $dir and gwmr.workspace = $workspace and gwm.state = 'completed'
    order by completed_at desc
    limit 1
)
select encode(data, 'base64') from recent_completed_work_manifest
where success and run_type in ('plan', 'autoplan')
