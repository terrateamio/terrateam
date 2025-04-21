with
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
),
latest_unlocks as (
    select
        repository,
        pull_number,
        max(unlocked_at) as unlocked_at
    from pull_request_unlocks
    group by repository, pull_number
),
latest_drift_unlocks as (
    select
        repository,
        max(unlocked_at) as unlocked_at
    from drift_unlocks
    group by repository
),
work_manifests_for_dirspace as (
    select distinct
        gwm.id
    from work_manifests as gwm
    inner join work_manifest_dirspaceflows as gwmdsfs
        on gwmdsfs.work_manifest = gwm.id
    inner join dirspaces
        on dirspaces.dir = gwmdsfs.path and dirspaces.workspace = gwmdsfs.workspace
    where gwm.state in ('queued', 'running')
          and gwm.repository = $repository
          and gwm.pull_number = $pull_number
          and (gwm.run_type in ('autoplan', 'plan') and $run_type in ('autoplan', 'plan'))
)
update work_manifests
set state = 'aborted', completed_at = now()
from work_manifests_for_dirspace
where work_manifests.id = work_manifests_for_dirspace.id
returning work_manifests.id
