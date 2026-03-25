select gwm.id
from github_work_manifests gwm
join adhoc_work_manifests awm on awm.work_manifest = gwm.id
where gwm.repository = $repository_id
  and gwm.run_type = $run_type
  and gwm.created_at >= now() - interval '30 seconds'
order by gwm.created_at desc
limit 1
