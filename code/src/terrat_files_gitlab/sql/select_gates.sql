with
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
)
select
  token,
  gate,
  gg.dir,
  gg.workspace
from gitlab_gates as gg
inner join gitlab_pull_requests as gpr
  on (gpr.repository = gg.repository and gpr.pull_number = gg.pull_number
      and (gpr.sha = gg.sha or gpr.merged_sha = gg.sha))
left join dirspaces as ds
  on ds.dir = gg.dir and ds.workspace = gg.workspace
where gg.repository = $repository and gg.pull_number = $pull_number
