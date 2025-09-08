-- TODO: query change_dirspaces
-- TODO: Ignore all work manifests that have a creation date smaller than the latest unlock, if applicable
with all_dirspaces as (
    select
        gcd.path as dir,
        gcd.workspace
    from github_change_dirspaces gcd
    inner join github_pull_requests gpr 
        on 
            gpr.base_sha = gcd.base_sha
        and gpr.sha = gcd.sha
    where
        gpr.repository = $repository
    and gpr.pull_number = $pull_number
),
from_work_manifest_data as (
    select
        wmr.work_manifest as work_manifest_id,
        wmr.path as dir,
        wmr.workspace,
        gwm.pull_number,
        gwm.repository,
        gwm.state,
        wmr.success,
        case 
          when gwm.run_type in ('autoplan', 'plan') then 'plan'
          when gwm.run_type in ('autoapply', 'apply', 'unsafe-apply') then 'apply'
          else gwm.run_type
        end as unified_run_type,
        gwm.created_at,
        gwm.completed_at
    from work_manifest_results wmr
    inner join github_work_manifests as gwm
        on gwm.id = wmr.work_manifest
    where
        gwm.pull_number = $pull_number
    and gwm.repository = $repository
    and gwm.run_type in ('autoplan', 'plan', 'autoapply', 'apply', 'unsafe-apply')
),
work_manifest_data_formatted as (
    select
        wmd.work_manifest_id,
        wmd.dir,
        wmd.workspace,
        wmd.state,
        wmd.success,
        wmd.unified_run_type,
        wmd.created_at,
        wmd.completed_at,
        -- first_value(wmd.work_manifest_id) over last_wm as last_work_manifest_id
        row_number() over last_wm as rn
    from from_work_manifest_data wmd
    window
        last_wm as (
            partition by 
                wmd.dir, 
                wmd.workspace,
                wmd.unified_run_type
            order by wmd.completed_at desc
        )
),
assemble_plan_info as (
    select
        wmdf.dir,
        wmdf.workspace,
        wmdf.state,
        wmdf.unified_run_type,
        wmdf.success,
        wso.payload->'diff'->'resource_changes' as json_changes
    from work_manifest_data_formatted wmdf
    join workflow_step_outputs as wso
        on wso.work_manifest = wmdf.work_manifest_id 
    where 
        wmdf.rn = 1
    and wso.step = 'tf/plan'
),
assemble_apply_info as (
    select
        wmdf.dir,
        wmdf.workspace,
        wmdf.state,
        wmdf.unified_run_type,
        wmdf.success,
        -- We get such changes from the 
        -- latest successful plan
        api.json_changes
    from work_manifest_data_formatted wmdf
    inner join assemble_plan_info as api
        on api.dir = wmdf.dir and api.workspace = wmdf.workspace
    where 
        wmdf.rn = 1
    and wmdf.unified_run_type = 'apply'
),
combined_results as (
    -- Get all apply results
    select aai.* from assemble_apply_info aai
    
    union all
    
    -- Get plan results only where no apply
    -- exists for the same dir/workspace
    select api.* from assemble_plan_info api
    where not exists (
        select 1 
        from assemble_apply_info aai 
        where aai.dir = api.dir 
        and aai.workspace = api.workspace
    )

    union all
    select
        ad.dir,
        ad.workspace,
        'queued' as state,
        'plan' as unified_run_type,
        false as success,
        null as json_changes
    from all_dirspaces ad
    left join assemble_apply_info as aai
        on aai.dir = ad.dir and aai.workspace = ad.workspace
    left join assemble_plan_info as api
        on api.dir = ad.dir and api.workspace = ad.workspace
    where 
        aai.dir is null
    and api.dir is null
),
final_results as (
    select 
        cr.*,
        row_number() over (
            partition by cr.dir, cr.workspace 
            order by case when cr.unified_run_type = 'apply' then 1 else 2 end
        ) as priority_rn
    from combined_results cr
),
group_counter as (
    select 
        fr.dir,
        fr.workspace,
        fr.state,
        fr.unified_run_type,
        fr.success, 
        -- Count resources by action type
        -- Create
        coalesce((
            select count(*)
            from jsonb_array_elements(fr.json_changes) as c
            where c->'change'->'actions' ? 'create'
        ),0) as created,
        -- Update
        coalesce((
            select count(*)
            from jsonb_array_elements(fr.json_changes) as c
            where c->'change'->'actions' ? 'update'
        ),0) as updated,
        -- Delete
        coalesce((
            select count(*)
            from jsonb_array_elements(fr.json_changes) as c
            where 
                c->'change'->'actions' ? 'delete'
            -- or c->'change'->'actions' @> '["delete", "create"]'::jsonb
        ),0) as deleted,
        -- Replaced
        -- https://developer.hashicorp.com/terraform/internals/json-format#change-representation
        coalesce((
            select count(*)
            from jsonb_array_elements(fr.json_changes) as c
            where 
                c->'change'->'actions' @> '["create", "delete"]'::jsonb
            or c->'change'->'actions' @> '["delete", "create"]'::jsonb
        ), 0) as replaced
    from final_results fr
    where fr.priority_rn = 1
)
select
    gc.dir,
    gc.workspace,
    gc.state,
    gc.unified_run_type,
    gc.success, 
    gc.created,
    gc.updated,
    gc.deleted,
    gc.replaced
from group_counter gc
