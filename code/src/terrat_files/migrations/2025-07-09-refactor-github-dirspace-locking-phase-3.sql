drop table github_dirspace_locking_migration;

alter table plans
    add column created_at timestamp with time zone not null default (now());
