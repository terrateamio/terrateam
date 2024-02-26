alter table github_drift_schedules
    add column updated_at timestamp with time zone not null default now();
