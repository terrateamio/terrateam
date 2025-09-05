with wm AS (
    select
        gwm.id as work_manifest_id,
        gwm.pull_number,
        gwm.repository,
        gwm.state,
        gwm.run_type,
        case 
          when gwm.run_type in ('autoplan', 'plan') then 'plan'
          when gwm.run_type in ('autoapply', 'apply', 'unsafe-apply') then 'apply'
          else gwm.run_type
        end as unified_run_type
    from github_work_manifests gwm
    where
        pull_number = 261
    and repository = 976747475
    --     pull_number = $pull_number
    -- and repository = $repository
)
select 
    wso.work_manifest, 
    wm.pull_number,
    wm.repository,
    wm.state,
    wm.run_type,
    wso.success, 
    wso.step,
    wso.payload->'diff'->'resource_changes' as raw_json
from workflow_step_outputs wso
join wm 
    on 
        wm.work_manifest_id = wso.work_manifest
    and wso.step in ('tf/plan', 'tf/apply') 
order by created_at desc;
