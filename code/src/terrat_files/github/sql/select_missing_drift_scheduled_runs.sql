with
ds as (
    select
        ds.name,
        grm.repository_id as repository,
        (case ds.schedule
         when 'hourly' then interval '1 hour'
         when 'daily' then interval '1 day'
         when 'weekly' then interval '1 week'
         when 'monthly' then interval '1 month'
         end) as schedule,
         nullif(branch, '') as branch,
         ds.reconcile,
         ds.tag_query,
         ds.updated_at,
         (current_date + ds.window_start at time zone current_setting('timezone')) as window_start,
         (current_date + ds.window_end at time zone current_setting('timezone')) as window_end,
         ds.repo as repo_core_id
    from drift_schedules as ds
    inner join github_repositories_map as grm
        on grm.core_id = ds.repo
    where schedule in ('hourly', 'daily', 'weekly', 'monthly')
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
),
chosen_drift_schedule as (
    select
        ds.name as drift_name,
        gir.installation_id as installation_id,
        gir.id as repository,
        gir.owner as owner,
        gir.name as name,
        ds.branch,
        ds.reconcile,
        ds.tag_query,
        dsw.window_start,
        dsw.window_end,
        ds.repo_core_id
    from ds
    inner join drift_schedules
        on drift_schedules.repo = ds.repo_core_id and drift_schedules.name = ds.name
    inner join github_installation_repositories as gir
        on gir.id = ds.repository
    inner join github_installations as gi
        on gi.id = gir.installation_id
    left join drift_schedule_windows as dsw
        on (dsw.repository, dsw.name) = (ds.repository, ds.name)
    where (dsw.window_start is null
           or (dsw.window_start <= current_timestamp and current_timestamp < dsw.window_end))
          and gi.state = 'installed'
          -- Running a schedule might fail immediately, so force at least 1 minute between tries
          and (drift_schedules.last_tried_at is null
               or drift_schedules.last_tried_at < now() - ds.schedule
               or drift_schedules.last_tried_at < drift_schedules.updated_at)
    limit 1
),
updated_last_tried as (
    update drift_schedules as ds
      set last_tried_at = now()
    from chosen_drift_schedule as cds
    where cds.repo_core_id = ds.repo
          and (cds.branch is null and ds.branch = '' or ds.branch = cds.branch)
          and ds.name = cds.drift_name
    returning cds.*
)
select
    drift_name,
    installation_id,
    repository,
    owner,
    name,
    reconcile,
    tag_query,
    window_start,
    window_end
from updated_last_tried
