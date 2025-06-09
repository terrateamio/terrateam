with
ds as (
    select
        name,
        repository,
        (case schedule
         when 'hourly' then interval '1 hour'
         when 'daily' then interval '1 day'
         when 'weekly' then interval '1 week'
         when 'monthly' then interval '1 month'
         end) as schedule,
         reconcile,
         tag_query,
         updated_at,
         (current_date + window_start at time zone current_setting('timezone')) as window_start,
         (current_date + window_end at time zone current_setting('timezone')) as window_end
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
dwms as (
    select
        gwm.repository as repository,
        gwm.created_at as created_at,
        gwm.state as state,
        row_number() over (partition by gwm.repository order by gwm.created_at desc) as rn
    from drift_work_manifests as dwm
    inner join github_work_manifests as gwm
        on gwm.id = dwm.work_manifest
    left join latest_drift_unlocks
        on latest_drift_unlocks.repository = gwm.repository
    where latest_drift_unlocks.repository is null or latest_drift_unlocks.unlocked_at < gwm.created_at
),
latest_drift_manifests as (
    select * from dwms where rn = 1
),
drift_schedule_windows as (
    select
        repository,
        name,
        window_start,
        (case
           when window_end < window_start then window_end + interval '1 day'
           else window_end
         end) as window_end
    from ds
    where window_start is not null and window_end is not null
)
select
    ds.name as drift_name,
    gir.installation_id as installation_id,
    gir.id as repository,
    gir.owner as owner,
    gir.name as name,
    ds.reconcile,
    ds.tag_query,
    dsw.window_start,
    dsw.window_end
from ds
inner join github_installation_repositories as gir
    on gir.id = ds.repository
inner join github_installations as gi
    on gi.id = gir.installation_id
left join latest_drift_manifests as ldm
    on ldm.repository = ds.repository
left join drift_schedule_windows as dsw
    on (dsw.repository, dsw.name) = (ds.repository, ds.name)
where (ldm.state is null or ldm.state <> 'running')
      and ((ldm.repository is null
            or ds.schedule < (current_timestamp - ldm.created_at)
            or ldm.created_at < ds.updated_at)
           and (dsw.window_start is null
                or (dsw.window_start <= current_timestamp and current_timestamp < dsw.window_end)))
      and gi.state = 'installed'
