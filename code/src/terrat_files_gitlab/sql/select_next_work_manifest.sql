with
latest_unlocks as (
    select
        repository,
        pull_number,
        max(unlocked_at) as unlocked_at
    from gitlab_pull_request_unlocks
    group by repository, pull_number
),
latest_drift_unlocks as (
    select
        repository,
        max(unlocked_at) as unlocked_at
    from gitlab_drift_unlocks
    group by repository
),
wms as (
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
    from gitlab_work_manifests as gwm
    left join drift_work_manifests as gdwm
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
    from work_manifest_dirspaceflows as gwmds
    inner join wms
        on gwmds.work_manifest = wms.id
),
queued_dirspaces_per_repo as (
    select distinct
        wms.repository as repository,
        wms.unified_run_type as unified_run_type,
        path,
        workspace
    from work_manifest_dirspaceflows as gwmds
    inner join wms
        on gwmds.work_manifest = wms.id
    where wms.state = 'queued'
),
running_dirspaces_per_repo as (
    select distinct
        wms.repository as repository,
        wms.unified_run_type as unified_run_type,
        path,
        workspace
    from work_manifest_dirspaceflows as gwmds
    inner join wms
        on gwmds.work_manifest = wms.id
    where wms.state = 'running'
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
    select distinct wms.id as id from wms
    inner join dirspaces_for_work_manifests as dswm
        on dswm.work_manifest = wms.id
    inner join apply_dirspaces_with_overlap as adso
        on adso.repository = wms.repository
           and adso.path = dswm.path
           and adso.workspace = dswm.workspace
),
next_work_manifests as (
    select
        wms.id,
        row_number() over (partition by wms.repository order by wms.priority, wms.created_at) as rn
    from wms
    left join rejected_work_manifests as rwm on rwm.id = wms.id
    where wms.state = 'queued' and rwm.id is null
)
select wm.id from work_manifests as wm
inner join next_work_manifests as nwm on nwm.id = wm.id
where nwm.rn = 1 and wm.state = 'queued'
for update of wm skip locked
limit 1
