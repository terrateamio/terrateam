with
dirspaces as (
    select path, workspace from unnest($dirs, $workspaces) as v(path, workspace)
),
latest_dirspace_work_manifests as(
    select distinct on (gwm.repository, gwm.pull_number, wmr.path, wmr.workspace)
        gwm.id,
        wmr.path,
        wmr.workspace,
        wmr.success
    from gitlab_work_manifests as gwm
    inner join gitlab_pull_requests as gpr
        on gpr.repository = gwm.repository
           and gpr.pull_number = gwm.pull_number
    inner join work_manifest_results as wmr
        on wmr.work_manifest = gwm.id
    left join gitlab_pull_request_latest_unlocks as unlocks
        on unlocks.repository = gwm.repository
           and unlocks.pull_number = gwm.pull_number
    where wmr.path = any($dirs)
          and wmr.workspace = any($workspaces)
          and gwm.repository = $repository
          and gwm.pull_number = $pull_number
          and (unlocks.unlocked_at is null or unlocks.unlocked_at < gwm.created_at)
          and ((gwm.base_sha = gpr.base_sha and gwm.sha = gpr.sha)
               or gpr.merged_at is not null and gpr.merged_at < gwm.created_at)
    order by gwm.repository, gwm.pull_number, wmr.path, wmr.workspace, gwm.created_at desc
)
select
    ds.path,
    ds.workspace
from dirspaces as ds
left join latest_dirspace_work_manifests as ldswm
    on ldswm.path = ds.path
       and ldswm.workspace = ds.workspace
left join gitlab_work_manifests as gwm
    on gwm.id = ldswm.id
left join plans
    on plans.work_manifest = gwm.id
       and plans.path = ds.path
       and plans.workspace = ds.workspace
where gwm.id is null or plans.data is null and ldswm.success
