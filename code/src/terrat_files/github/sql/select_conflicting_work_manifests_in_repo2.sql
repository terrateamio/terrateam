with
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
),
wm as (
   select
     gwm.*
   from github_work_manifests as gwm
   left join github_pull_request_latest_unlocks as latest_unlocks
        on latest_unlocks.repository = gwm.repository and latest_unlocks.pull_number = gwm.pull_number
   left join github_drift_latest_unlocks as latest_drift_unlocks
        on latest_drift_unlocks.repository = gwm.repository
   where gwm.repository = $repository
         and gwm.state in ('queued', 'running')
         and (latest_unlocks.unlocked_at is null or latest_unlocks.unlocked_at < gwm.created_at)
         and (latest_drift_unlocks.unlocked_at is null or latest_drift_unlocks.unlocked_at < gwm.created_at)
),
work_manifests_for_dirspace as (
    select
        gwm.id,
-- Consider a work manifest as maybe stale if we have no run id after a minute
-- or it was created over 10 minutes ago
        ((gwm.run_id is null and (now() - gwm.created_at > interval '1 minutes'))
         or (gwm.run_id is not null and (now() - gwm.created_at > interval '1 hour'))) as maybe_stale
    from dirspaces
    inner join work_manifest_dirspaceflows as gwmdsfs
        on dirspaces.dir = gwmdsfs.path and dirspaces.workspace = gwmdsfs.workspace
    inner join wm as gwm
        on gwmdsfs.work_manifest = gwm.id
    where gwm.repository = $repository
    group by gwm.id, gwm.run_id, gwm.created_at
)
select
    gwm.id,
    work_manifests_for_dirspace.maybe_stale
from wm as gwm
inner join work_manifests_for_dirspace
    on work_manifests_for_dirspace.id = gwm.id
left join github_pull_request_latest_unlocks as latest_unlocks
    on latest_unlocks.repository = gwm.repository and latest_unlocks.pull_number = gwm.pull_number
left join drift_work_manifests as gdwm
    on gdwm.work_manifest = gwm.id
left join github_drift_latest_unlocks as latest_drift_unlocks
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
