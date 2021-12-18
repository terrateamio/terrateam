with
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
),
all_completed_runs as (
    select
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        gwmds.path as path,
        gwmds.workspace as workspace,
        coalesce(gwmr.success, false) as success,
        gwm.run_type as run_type,
        (case gwm.run_type
         when 'autoapply' then 'apply'
         when 'apply' then 'apply'
         when 'autoplan' then 'plan'
         when 'plan' then 'plan'
         end) as unified_run_type,
        gwm.completed_at as completed_at
    from github_pull_requests as gpr
    inner join github_work_manifests as gwm
        on gpr.base_sha = gwm.base_sha and (gpr.sha = gwm.sha or (gpr.state = 'merged' and gpr.merged_sha = gwm.sha))
    inner join github_work_manifest_dirspaceflows as gwmds
        on gwmds.work_manifest = gwm.id
    left join github_work_manifest_results as gwmr
        on gwmr.work_manifest = gwmds.work_manifest and gwmr.path = gwmds.path and gwmr.workspace = gwmds.workspace
    where gwm.completed_at is not null
),
completed_runs as (
    select
        repository,
        pull_number,
        path,
        workspace,
        success,
        run_type,
        unified_run_type,
        completed_at,
        row_number() over (partition by
                               repository,
                               pull_number,
                               path,
                               workspace,
                               unified_run_type
                           order by completed_at desc) as rn
    from all_completed_runs
),
latest_completed_runs as (
    select * from completed_runs where rn = 1
),
-- We only wants plans from this pull number
latest_completed_plans as (
    select * from latest_completed_runs
    where unified_run_type = 'plan' and repository = $repository and pull_number = $pull_number
),
-- But we'll takes applies from any pull number.  This means that if someone
-- successfully applies a previous plan, they must re-plan to apply again, which
-- is what we want.
latest_completed_applies as (
    select * from latest_completed_runs
    where unified_run_type = 'apply' and repository = $repository
)
-- Select all those dirspaces that DO NOT have a valid plan
select distinct ds.dir, ds.workspace
from dirspaces as ds
left join latest_completed_plans as plans
    on plans.path = ds.dir and plans.workspace = ds.workspace
left join latest_completed_applies as applies
    on applies.repository = plans.repository
       and applies.path = plans.path and applies.workspace = plans.workspace
where plans.path is null or not plans.success or plans.completed_at < applies.completed_at
