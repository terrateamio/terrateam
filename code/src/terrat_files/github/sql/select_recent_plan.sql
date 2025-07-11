with
wm as (
     select
         gwm.id as id,
         gwm.repository as repository,
         gwm.pull_number as pull_number,
         gwm.sha as sha,
         gwm.base_sha as base_sha
     from github_work_manifests as gwm
     where gwm.id = $id and gwm.state = 'running' and gwm.run_type in ('autoapply', 'apply')
),
latest_completed_plan as (
   select
       gwm.id
   from github_work_manifests as gwm
   inner join wm
       on wm.repository = gwm.repository
   inner join work_manifest_results as wmr
       on wmr.work_manifest = gwm.id
          and wmr.path = $dir
          and wmr.workspace = $workspace
   where gwm.run_type in ('plan', 'autoplan')
         and gwm.completed_at is not null
-- Either we're running the apply for the pull request in which case this will
-- be the most recent run for that dirspace in that PR.  Or it's not (drift) in
-- which case if it is the most recent run for the exact same head and base sha
-- as the current work manifest.
         and ((wm.pull_number is not null and gwm.pull_number = wm.pull_number)
              or (wm.pull_number is null and gwm.pull_number is null and wm.base_sha = gwm.base_sha and wm.sha = wm.sha))
   order by gwm.created_at desc
   limit 1
),
recent_plan as (
    select
        plans.data,
        wmr.success
    from plans
    inner join latest_completed_plan as lcp
        on lcp.id = plans.work_manifest
    inner join work_manifest_results as wmr
        on wmr.work_manifest = lcp.id
           and wmr.path = plans.path
           and wmr.workspace = plans.workspace
    where plans.path = $dir and plans.workspace = $workspace
)
select encode(data, 'base64') from recent_plan
where data is not null and success
