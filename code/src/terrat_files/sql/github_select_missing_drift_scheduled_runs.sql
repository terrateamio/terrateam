with
drift_schedules as (
    select
        repository,
        (case schedule
         when 'hourly' then interval '1 hour'
         when 'daily' then interval '1 day'
         when 'weekly' then interval '1 week'
         when 'monthly' then interval '1 month'
         end) as schedule
    from github_drift_schedules
    where schedule in ('hourly', 'daily', 'weekly', 'monthly')
    for update skip locked
),
latest_drift_unlocks as (
    select
        repository,
        max(unlocked_at) as unlocked_at
    from github_drift_unlocks
    group by repository
),
drift_work_manifests as (
    select
        gwm.repository as repository,
        gwm.created_at as created_at,
        gwm.state as state,
        row_number() over (partition by gwm.repository order by gwm.created_at desc) as rn
    from github_drift_work_manifests as dwm
    inner join github_work_manifests as gwm
        on gwm.id = dwm.work_manifest
    left join latest_drift_unlocks
        on latest_drift_unlocks.repository = gwm.repository
    where latest_drift_unlocks.repository is null or latest_drift_unlocks.unlocked_at < gwm.created_at
),
latest_drift_manifests as (
    select * from drift_work_manifests where rn = 1
)
select
    gir.installation_id as installation_id,
    gir.id as repository,
    gir.owner as owner,
    gir.name as name
from drift_schedules as ds
inner join github_installation_repositories as gir
    on gir.id = ds.repository
inner join github_installations as gi
    on gi.id = gir.installation_id
left join latest_drift_manifests as ldm
    on ldm.repository = ds.repository
where (ldm.state is null or ldm.state <> 'running')
      and (ldm.repository is null or ds.schedule < (now() - ldm.created_at))
      and gi.state = 'installed'
