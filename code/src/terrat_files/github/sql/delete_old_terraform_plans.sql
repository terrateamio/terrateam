-- This requires a bit of sympathy between the client and server.  Technically
-- the client is in charge of how to represent plans.  However, when cleaning up
-- old plans, we want to ensure any data it references is deleted.  So we need
-- to interpret the opaque plan data in order to determine which data is linked.
--
-- Linking data could also be an attack vector, so we cannot just blindly delete
-- a linked plan (an attacker could create a plan whose '@plan_data' field links
-- to data they do not own, so we also need to be careful there.
--
-- To delete data we will take two paths:
--
-- 1. Plans with changes.
--
-- 2. Plans without changes.
--
-- For plans with changes:
--
-- 1. Find all old plans with changes.
--
-- 2. Find all old plans whose opaque data field can be interpreted as JSON.
--
-- 3. For any plans which have method = 'terrateam' and version = 2, delete the
-- matching kv_store where key = 'data->@plan_data' and namespace corresponds to
-- the namespace of the installation.
--
-- 4. Delete the actual plan entry
--
-- 5. For any plans whose data cannot be interpreted as json, just delete them.
--
-- For plans without changes:
--
-- 1. Find all old plans without changes.
--
-- 2. Find all old plans whos opaque data field can be interpreted as JSON.
--
-- 3. For any plans which have method = 'terrateam' and version = 2, delete the
-- matching kv_store where key = 'data->@plan_data' and namespace corresponds to
-- the namespace of the installation.
--
-- 4. Set the plan data to null.
--
-- 5. For any plans whose data cannot be interpreted as json, just set the data
-- field to null.
with
-- All plans that can be deleted and limit to 1000 so we don't overload the DB.
-- The 1000 is arbitrary.
deleteable_plans as (
    select
        p.*
    from plans as p
    inner join github_work_manifests as gwm
        on gwm.id = p.work_manifest
    where p.created_at < now() - interval '14 days' and p.has_changes and data is not null
    limit 1000
),
-- All plans that must stay because they don't have changes in them but we want
-- to delete all data related to it and limit to 1000 so we don't overload the
-- DB.  The 1000 is arbitrary.
updateable_plans as (
    select
        p.*
    from plans as p
    inner join github_work_manifests as gwm
        on gwm.id = p.work_manifest
    where p.created_at < now() - interval '14 days' and not p.has_changes and data is not null
    limit 1000
),
all_changeable_plans as (
    select * from deleteable_plans
    union all
    select * from updateable_plans
),
json_plans as (
    select
        work_manifest,
        path,
        workspace,
        convert_from(data, 'UTF8')::jsonb as data
    from all_changeable_plans
),
non_json_plans as (
    select
        p.work_manifest,
        p.path,
        p.workspace
    from all_changeable_plans as p
    left join json_plans as jp
        on jp.work_manifest = p.work_manifest
           and jp.path = p.path
           and jp.workspace = p.workspace
   where jp.work_manifest is null
),
deleted_kv_store_plans as (
    delete from kv_store
    using github_work_manifests as gwm, json_plans as p
    where p.work_manifest = gwm.id
          and p.data->>'method' = 'terrateam'
          and p.data->>'version' = '2'
          and kv_store.namespace = 'github:' || gwm.installation_id
          and kv_store.key = p.data->'data'->>'@plan_data'
),
deleted_plans as (
    delete from plans as p
    using deleteable_plans as dp
    where dp.work_manifest = p.work_manifest
          and dp.path = p.path
          and dp.workspace = p.workspace
    returning (p.work_manifest, p.path, p.workspace)
),
updated_plans as (
    update plans as p
        set data = null
    from updateable_plans as up
    where up.work_manifest = p.work_manifest
          and up.path = p.path
          and up.workspace = p.workspace
    returning (p.work_manifest, p.path, p.workspace)
),
all_updates as (
    select * from deleted_plans
    union all
    select * from updated_plans
)
select count(*) from all_updates
