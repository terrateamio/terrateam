alter table github_drift_schedules
      add column name text not null default 'default',
      add column window_start time with time zone,
      add column window_end time with time zone;

alter table github_drift_schedules
      drop constraint github_drift_schedules_pkey;

alter table github_drift_schedules
      add primary key (repository, name);
