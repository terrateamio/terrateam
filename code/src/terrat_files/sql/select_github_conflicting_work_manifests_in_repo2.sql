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
        gwm.id,
-- Consider a work manifest as maybe stale if we have no run id after a minute
-- or it was created over 10 minutes ago
        ((gwm.run_id is null and (now() - gwm.created_at > interval '1 minutes'))
         or (gwm.run_id is not null and (now() - gwm.created_at > interval '10 minutes'))) as maybe_stale
    from github_work_manifests as gwm
    inner join github_work_manifest_dirspaceflows as gwmdsfs
        on gwmdsfs.work_manifest = gwm.id
    inner join dirspaces
        on dirspaces.dir = gwmdsfs.path and dirspaces.workspace = gwmdsfs.workspace
)
select
    gwm.id,
    work_manifests_for_dirspace.maybe_stale
from github_work_manifests as gwm
inner join work_manifests_for_dirspace
    on work_manifests_for_dirspace.id = gwm.id
left join github_pull_requests as gpr
    on gpr.repository = gwm.repository and gpr.pull_number = gwm.pull_number
left join latest_unlocks
    on latest_unlocks.repository = gpr.repository and latest_unlocks.pull_number = gpr.pull_number
left join github_drift_work_manifests as gdwm
    on gdwm.work_manifest = gwm.id
left join latest_drift_unlocks
    on latest_drift_unlocks.repository = gwm.repository
where gwm.repository = $repository
      and gwm.state in ('queued', 'running')
-- Don't consider index runs conflicting, they don't change the underlying infra
      and gwm.run_kind <> 'index'
      and ((gwm.pull_number is not null
            and (latest_unlocks.unlocked_at is null or latest_unlocks.unlocked_at < gwm.created_at))
           or (gdwm.work_manifest is not null
               and (latest_drift_unlocks.unlocked_at is null or latest_drift_unlocks.unlocked_at < gwm.created_at)))
      and ((gwm.pull_number is not null and gwm.pull_number = $pull_number)
           or ($run_type in ('autoapply', 'apply', 'unsafe-apply'))
           or work_manifests_for_dirspace.maybe_stale)
order by gwm.created_at