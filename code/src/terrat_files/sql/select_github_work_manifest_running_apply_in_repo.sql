with
unlocks as (
    select
        repository,
        pull_number,
        unlocked_at,
        row_number() over (partition by repository, pull_number order by unlocked_at desc) as rn
    from github_pull_request_unlocks
),
latest_unlocks as (
    select * from unlocks where rn = 1
)
select
    gwm.base_sha,
    to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
    gwm.sha,
    gwm.id,
    gwm.run_id,
    gwm.run_type,
    gwm.tag_query,
    gpr.base_branch,
    gpr.branch,
    gwm.pull_number,
    gpr.state,
    gpr.merged_sha,
    gpr.merged_at
from github_work_manifests as gwm
inner join github_pull_requests as gpr
    on gpr.repository = gwm.repository and gpr.pull_number = gwm.pull_number
left join latest_unlocks
    on latest_unlocks.repository = gpr.repository and latest_unlocks.pull_number = gpr.pull_number
where gwm.repository = $repository
      and gwm.state = 'running'
      and gwm.run_type in ('apply', 'autoapply')
      and (latest_unlocks.unlocked_at is null
           or latest_unlocks.unlocked_at < gwm.created_at)
