with
latest_unlocks as (
    select
        repository,
        pull_number,
        max(unlocked_at) as unlocked_at
    from github_pull_request_unlocks
    where repository = $repo_id and pull_number = $pull_number
    group by repository, pull_number
),
wm as (
    select
        gwm.id as id,
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        gwm.base_sha as base_sha,
        gwm.sha as sha,
        (case
           when gwm.run_type in ('autoapply', 'apply', 'unsafe-apply') then 'apply'
           when gwm.run_type in ('autoplan', 'plan') then 'plan'
           else gwm.run_type
         end) as run_type,
        gwm.created_at as created_at
    from github_work_manifests as gwm
    left join latest_unlocks as unlocks
        on unlocks.repository = gwm.repository and unlocks.pull_number = gwm.pull_number
    where gwm.run_kind = 'pr' and (unlocks.unlocked_at is null or unlocks.unlocked_at < gwm.created_at)
),
--- In the case that the pull request being evaluated here is merged, we want to
--- use the SHA information of the most recently merged pull request (because
--- the work manifest will run against the latest sha).
latest_merged_pull_request as (
    select
        repository,
        pull_number,
        merged_sha
    from github_pull_requests as gpr
    where state = 'merged' and repository = $repo_id
    order by merged_at desc
    limit 1
),
work_manifest_results as (
    select
        gwm.id as id,
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        gwm.base_sha as base_sha,
        gwm.sha as sha,
        gwm.run_type as run_type,
        gwmr.path as path,
        gwmr.workspace as workspace,
        gwmr.success as success,
        row_number() over (partition by
                               gwm.repository,
                               gwmr.path,
                               gwmr.workspace
                           order by gwm.created_at desc) as rn
    from github_work_manifests as gwm
    inner join work_manifest_results as gwmr
        on gwmr.work_manifest = gwm.id
    order by gwm.created_at desc
),
plans_with_no_changes as (
    select distinct
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        results.path as path,
        results.workspace as workspace
    from github_pull_requests as gpr
    left join latest_merged_pull_request as lmpr
        on gpr.repository = lmpr.repository
    left join work_manifest_results as results
        on results.repository = gpr.repository and results.pull_number = gpr.pull_number
           and results.base_sha = gpr.base_sha
           and (results.sha = gpr.sha or (gpr.state = 'merged' and results.sha = lmpr.merged_sha))
    left join plans as gtp
        on gtp.work_manifest = results.id and gtp.path = results.path and gtp.workspace = results.workspace
    where results.rn = 1 and results.run_type = 'plan' and results.success and not gtp.has_changes
),
applied_dirspaces as (
    select distinct
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        results.path as path,
        results.workspace as workspace
    from github_pull_requests as gpr
    left join latest_merged_pull_request as lmpr
        on gpr.repository = lmpr.repository
    left join work_manifest_results as results
        on results.repository = gpr.repository and results.pull_number = gpr.pull_number
           and results.base_sha = gpr.base_sha
           and (results.sha = gpr.sha or (gpr.state = 'merged' and results.sha = lmpr.merged_sha))
    where results.rn = 1 and results.run_type = 'apply' and results.success
)
select distinct
    applied.path,
    applied.workspace
from github_pull_requests as gpr
inner join github_installation_repositories as gir
    on gir.id = gpr.repository
left join applied_dirspaces as applied
    on gpr.repository = applied.repository and gpr.pull_number = applied.pull_number
where gpr.repository = $repo_id and gpr.pull_number = $pull_number and applied.path is not null

UNION

select distinct
    pwnc.path,
    pwnc.workspace
from github_pull_requests as gpr
inner join github_installation_repositories as gir
    on gir.id = gpr.repository
left join plans_with_no_changes as pwnc
    on pwnc.repository = gpr.repository and pwnc.pull_number = gpr.pull_number
where gpr.repository = $repo_id and gpr.pull_number = $pull_number and pwnc.path is not null
