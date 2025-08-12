with
latest_github_work_manifest as (
    select
        gwm.created_at as created_at,
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        row_number() over (partition by gwm.repository, gwm.pull_number order by gwm.created_at desc) as rn
    from github_work_manifests as gwm
    inner join github_installation_repositories as gir
        on gwm.repository = gir.id
    where gir.installation_id = $installation_id
    order by gwm.created_at desc
)
select
    gpr.base_branch as base_branch,
    gpr.base_sha as base_sha,
    gpr.branch as branch,
    to_char(lgwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as latest_work_manifest_run_at,
    to_char(gpr.merged_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as merged_at,
    gpr.merged_sha as merged_sha,
    gir.name as name,
    gir.owner as owner,
    gpr.pull_number as pull_number,
    gpr.repository as repository,
    gpr.sha as sha,
    gpr.state as state,
    gpr.title as title,
    gpr.username as uesrname
from github_pull_requests as gpr
inner join github_installation_repositories as gir
    on gpr.repository = gir.id
inner join github_user_installations2 as gui
    on gir.installation_id = gui.installation_id
left join latest_github_work_manifest as lgwm
    on gpr.repository = lgwm.repository and gpr.pull_number = lgwm.pull_number
where (lgwm.rn is null or lgwm.rn = 1) and gir.installation_id = $installation_id
      and ($pull_number is null or gpr.pull_number = $pull_number)
      and gui.user_id = $user
