WITH from_work_manifest AS (
  select
    pull_request,
    run_type
  from work_manifests
  where id = $work_manifest_id
)
select gwmc.comment_id
from github_work_manifest_comments gwmc
inner join work_manifest wm ON gwmc.work_manifest = wm.id
inner join from_work_manifest fwm ON fwm.pull_request = wm.pull_request
where 
    gwmc.dir = $dir 
and gwmc.workspace = $workspace
and 
    ((fwm.run_type IN ('autoplan', 'plan') and wm.run_type IN ('autoplan', 'plan'))
        or 
    (fwm.run_type IN ('autoapply', 'apply') and wm.run_type IN ('autoapply', 'apply')))
