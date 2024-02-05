with
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
work_manifests as (
    select
        gwm.id as id,
        gwm.created_at as created_at,
        gwm.repository as repository,
        gwm.state as state,
        (case gwm.run_type
         when 'autoapply' then 'apply'
         when 'apply' then 'apply'
         when 'unsafe-apply' then 'apply'
         when 'autoplan' then 'plan'
         when 'plan' then 'plan'
         end) as unified_run_type,
        (case gwm.run_type
         when 'autoapply' then 0
         when 'apply' then 0
         when 'autoplan' then 1
         when 'plan' then 1
         end) as priority
    from github_work_manifests as gwm
    left join github_drift_work_manifests as gdwm
        on gdwm.work_manifest = gwm.id
    left join latest_unlocks as unlocks
        on unlocks.repository = gwm.repository and unlocks.pull_number = gwm.pull_number
    left join latest_drift_unlocks as drift_unlocks
        on drift_unlocks.repository = gwm.repository
    where (gwm.run_kind = 'pr'
           and (unlocks.unlocked_at is null or unlocks.unlocked_at < gwm.created_at))
          or (gwm.run_kind = 'drift'
              and (drift_unlocks.unlocked_at is null or drift_unlocks.unlocked_at < gwm.created_at))
          or gwm.run_kind = 'index'
),
dirspaces_for_work_manifests as (
    select
        work_manifest,
        path,
        workspace
    from github_work_manifest_dirspaceflows as gwmds
    inner join work_manifests as wm
        on gwmds.work_manifest = wm.id
),
queued_dirspaces_per_repo as (
    select distinct
        wm.repository as repository,
        wm.unified_run_type as unified_run_type,
        path,
        workspace
    from github_work_manifest_dirspaceflows as gwmds
    inner join work_manifests as wm
        on gwmds.work_manifest = wm.id
    where wm.state = 'queued'
),
running_dirspaces_per_repo as (
    select distinct
        wm.repository as repository,
        wm.unified_run_type as unified_run_type,
        path,
        workspace
    from github_work_manifest_dirspaceflows as gwmds
    inner join work_manifests as wm
        on gwmds.work_manifest = wm.id
    where wm.state = 'running'
),
-- Find all those queued dirspaces that have running instance where the running
-- instance is an apply.  These work manifests cannot be run because the apply
-- is blocking them
apply_dirspaces_with_overlap as (
    select distinct
        qds.repository as repository,
        qds.path as path,
        qds.workspace as workspace
    from queued_dirspaces_per_repo as qds
    inner join running_dirspaces_per_repo as rds
        on qds.repository = rds.repository
           and qds.path = rds.path
           and qds.workspace = rds.workspace
    where rds.unified_run_type = 'apply'
),
-- Reject all those work manifests that have a dirspace in the overlapping apply
-- table
rejected_work_manifests as (
    select distinct wm.id as id from work_manifests as wm
    inner join dirspaces_for_work_manifests as dswm
        on dswm.work_manifest = wm.id
    inner join apply_dirspaces_with_overlap as adso
        on adso.repository = wm.repository
           and adso.path = dswm.path
           and adso.workspace = dswm.workspace
),
next_work_manifests as (
    select
        wm.id,
        row_number() over (partition by wm.repository order by wm.priority, wm.created_at) as rn
    from work_manifests as wm
    left join rejected_work_manifests as rwm on rwm.id = wm.id
    where wm.state = 'queued' and rwm.id is null
)
update github_work_manifests set state = 'running' where id = (
    select gwm.id from github_work_manifests as gwm
    inner join next_work_manifests as nwm on nwm.id = gwm.id
    where nwm.rn = 1
    for update skip locked
    limit 1)
returning id
