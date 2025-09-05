with work_manifest_data AS (
    select
        gwm.id as work_manifest_id,
        gwm.pull_number,
        gwm.repository,
        jsonb_array_elements(gwm.dirspaces) as dirspace,
        gwm.state,
        case 
          when gwm.run_type in ('autoplan', 'plan') then 'plan'
          when gwm.run_type in ('autoapply', 'apply', 'unsafe-apply') then 'apply'
          else gwm.run_type
        end as unified_run_type,
        gwm.created_at,
        gwm.completed_at
    from github_work_manifests gwm
    where
        pull_number = 261
    and repository = 976747475
    and gwm.dirspaces is not null
    --     pull_number = $pull_number
    -- and repository = $repository
),
work_manifest_formated AS (
    select
        wmd.work_manifest_id,
        wmd.pull_number,
        wmd.repository,
        wmd.dirspace->>'dir' as dir,
        wmd.dirspace->>'workspace' as workspace,
        wmd.state,
        wmd.unified_run_type,
        wmd.created_at,
        wmd.completed_at,
        first_value(wmd.work_manifest_id) over (
            partition by wmd.pull_number, wmd.repository, wmd.dirspace->>'dir', wmd.dirspace->>'workspace', wmd.state, wmd.unified_run_type
            order by wmd.completed_at desc
        ) as last_work_manifest_id
    from work_manifest_data wmd
),
select_last_work_manifests_for_dirspaces AS (
    select
        wmf.work_manifest_id,
        wmf.pull_number,
        wmf.repository,
        wmf.dir,
        wmf.workspace,
        wmf.state,
        wmf.unified_run_type,
        wmf.created_at,
        wmf.completed_at
    from work_manifest_formated wmf
    where wmf.work_manifest_id = wmf.last_work_manifest_id
),
merged_info AS (
    select 
        sl.work_manifest_id, 
        sl.pull_number,
        sl.repository,
        sl.dir,
        sl.workspace,
        sl.state,
        sl.unified_run_type,
        wso.success, 
        jsonb_pretty(wso.payload->'diff'->'resource_changes') as raw_json,
        sl.created_at,
        sl.completed_at,
        row_number() OVER (
            PARTITION BY sl.work_manifest_id, sl.dir, sl.workspace
            ORDER BY sl.dir, sl.workspace
        ) as rn
    from workflow_step_outputs wso
    join select_last_work_manifests_for_dirspaces as sl
        on 
            wso.work_manifest = sl.work_manifest_id 
        -- and wso.step in ('tf/plan', 'tf/apply') 
        and wso.step in ('tf/plan') 
)
select *
from merged_info c
where rn = 1;
