with grouped_work_manifest_by_id as (
  select
    wm.pull_request,
    wm.run_type,
    case 
      when wm.run_type in ('autoplan', 'plan') then 'plan'
      when wm.run_type in ('autoapply', 'apply') then 'apply'
      else wm.run_type
    end as run_group
  from work_manifests wm
  where id = $work_manifest
),
grouped_work_manifest_with_pr as (
  select
    wm.id,
    wm.pull_request,
    wm.run_type,
    case 
      when wm.run_type in ('autoplan', 'plan') then 'plan'
      when wm.run_type in ('autoapply', 'apply') then 'apply'
      else wm.run_type
    end as run_group
  from work_manifests wm
)
select 
    gwmc.comment_id
from github_work_manifest_comments gwmc
inner join grouped_work_manifest_with_pr wmpr ON gwmc.work_manifest = wmpr.id
inner join grouped_work_manifest_by_id wmid ON (
        wmid.pull_request = wmpr.pull_request 
    and wmid.run_group = wmpr.run_group
)
where 
    gwmc.dir = $dir 
and gwmc.workspace = $workspace
