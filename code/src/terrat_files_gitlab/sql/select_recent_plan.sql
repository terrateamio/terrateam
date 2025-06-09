with
wm as (
     select
         gwm.id as id,
         gwm.repository as repository,
         gwm.pull_number as pull_number,
         gwm.sha as sha,
         gwm.base_sha as base_sha
     from gitlab_work_manifests as gwm
     where gwm.id = $id and gwm.state = 'running' and gwm.run_type in ('autoapply', 'apply')
),
recent_completed_work_manifest as (
    select
        gwm.run_type as run_type,
        gwmr.success as success,
        gtp.data as data
    from work_manifest_results as gwmr
    inner join gitlab_work_manifests as gwm
        on gwm.id = gwmr.work_manifest
    inner join wm
        on wm.repository = gwm.repository
    inner join work_manifest_results as gwmr
        on gwmr.work_manifest = gwm.id
    left join github_pull_requests as gpr
        on gpr.repository = gwm.repository
           and gpr.pull_number = gwm.pull_number
    left join plans
        on plans.work_manifest = gwmr.work_manifest
           and plans.path = gwmr.path
           and plans.workspace = gwmr.workspace
    where gwm.run_type in ('plan', 'autoplan')
          and gwm.completed_at is not null
          and gwmr.path = $dir
          and gwmr.workspace = $workspace
-- Either we're running the apply for the pull request in which case this will
-- be the most recent run for that dirspace in that PR.  Or it's not (drift) in
-- which case if it is the most recent run for the exact same head and base sha
-- as the current work manifest.
          and ((wm.pull_number is not null and wm.pull_number = gwm.pull_number)
               or (wm.pull_number is null and gwm.pull_number is null and wm.base_sha = gwm.base_sha and wm.sha = gwm.sha))
    order by gwm.created_at desc
    limit 1
)
select encode(data, 'base64') from recent_completed_work_manifest
where data is not null and success and completed_at is not null
