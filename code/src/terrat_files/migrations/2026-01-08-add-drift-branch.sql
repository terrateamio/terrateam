-- We are cheating a bit and using empty string to signify 'default' branch so
-- that we can add the branch to the primary key.
alter table drift_schedules
  add column branch text not null default '',
  add column last_tried_at timestamp with time zone;

alter table drift_schedules drop constraint drift_schedules_pkey;

alter table drift_schedules add primary key (repo, branch, name);

create or replace view github_drift_schedules as
       select
        ds.reconcile as reconcile,
        grm.repository_id as repository,
        ds.schedule as schedule,
        ds.updated_at as updated_at,
        ds.tag_query as tag_query,
        ds.name as name,
        ds.window_start as window_start,
        ds.window_end as window_end,
        ds.branch as branch,
        ds.last_tried_at as last_tried_at
       from drift_schedules as ds
       inner join github_repositories_map as grm
             on ds.repo = grm.core_id;

create or replace view gitlab_drift_schedules as
       select
        ds.reconcile as reconcile,
        grm.repository_id as repository,
        ds.schedule as schedule,
        ds.updated_at as updated_at,
        ds.tag_query as tag_query,
        ds.name as name,
        ds.window_start as window_start,
        ds.window_end as window_end,
        ds.branch as branch,
        ds.last_tried_at as last_tried_at
       from drift_schedules as ds
       inner join gitlab_repositories_map as grm
             on ds.repo = grm.core_id;
