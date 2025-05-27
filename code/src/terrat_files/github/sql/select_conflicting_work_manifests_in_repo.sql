with
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
),
latest_unlocks as (
    select
        repository,
        pull_number,
        max(unlocked_at) as unlocked_at
    from github_pull_request_unlocks
    group by repository, pull_number
),
latest_drift_unlocks as (
    select
        repository,
        max(unlocked_at) as unlocked_at
    from github_drift_unlocks
    group by repository
),
work_manifests_for_dirspace as (
    select distinct
        gwm.id
    from github_work_manifests as gwm
    inner join work_manifest_dirspaceflows as gwmdsfs
        on gwmdsfs.work_manifest = gwm.id
    inner join dirspaces
        on dirspaces.dir = gwmdsfs.path and dirspaces.workspace = gwmdsfs.workspace
)
select
    gwm.base_sha,
    to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
    gwm.sha,
    gwm.id,
    gwm.run_id,
    gwm.run_type,
    gwm.tag_query,
    gpr.base_branch,
    gpr.branch,
    gwm.pull_number,
    gpr.state,
    gpr.merged_sha,
    gpr.merged_at,
    gwm.state,
    gwm.run_kind,
    gpr.title,
    gwm.username,
    gpr.username
from github_work_manifests as gwm
inner join work_manifests_for_dirspace
    on work_manifests_for_dirspace.id = gwm.id
left join github_pull_requests as gpr
    on gpr.repository = gwm.repository and gpr.pull_number = gwm.pull_number
left join latest_unlocks
    on latest_unlocks.repository = gpr.repository and latest_unlocks.pull_number = gpr.pull_number
left join drift_work_manifests as gdwm
    on gdwm.work_manifest = gwm.id
left join latest_drift_unlocks
    on latest_drift_unlocks.repository = gwm.repository
where gwm.repository = $repository
      and gwm.state in ('queued', 'running')
      and ((gwm.pull_number is not null
            and (latest_unlocks.unlocked_at is null or latest_unlocks.unlocked_at < gwm.created_at))
           or (gdwm.work_manifest is not null
               and (latest_drift_unlocks.unlocked_at is null or latest_drift_unlocks.unlocked_at < gwm.created_at)))
      and ((gwm.pull_number is not null and gwm.pull_number = $pull_number)
           or ($run_type in ('autoapply', 'apply', 'unsafe-apply')))
order by gwm.created_at
