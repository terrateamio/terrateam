alter table plans
    alter column data drop not null;

create index plan_created_at_has_changes_wm
    on plans (created_at, has_changes, work_manifest)
    where data is not null;
