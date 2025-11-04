with deleted_plans as (
    delete from plans as p
    using github_work_manifests as gwm
    where p.work_manifest = gwm.id and gwm.created_at < now() - interval '14 days' and p.has_changes
    returning (p.work_manifest, p.path, p.workspace)
),
-- Plans that don't have changes are used as a record of if a dirspace should be
-- considered applied.  This is probably not great, but it's quite easy to do in
-- the current system.  However, for those plan rows that we want to keep
-- around, we need to empty the data so that we don't store it and it takes up
-- less space.
empty_plans_limited as (
    select
        p.work_manifest as id
    from plans as p
    inner join github_work_manifests as gwm
        on gwm.id = p.work_manifest
    where p.created_at < now() - interval '14 days' and not p.has_changes and data is not null and gwm.id = p.work_manifest
    order by p.created_at    
    limit 5000
),
empty_plans as (
    update plans as p
        set data = null
    from empty_plans_limited as e
    where p.work_manifest = e.id
    returning (p.work_manifest, p.path, p.workspace)
),
all_updates as (
    select * from deleted_plans
    union all
    select * from empty_plans
)
select count(*) from all_updates
