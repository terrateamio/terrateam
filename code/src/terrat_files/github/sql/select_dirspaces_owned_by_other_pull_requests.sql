with
dirspaces as materialized (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
),
-- First things we'll do is for each pull request determine all of the dirspaces
-- that need to be applied.
--
-- We need all those applies that were done on commits other than the current on
-- the PR is.  This is because if we have commit C1 with a change in dirs D1 and
-- D2 in it and D1 is applied, then in commit C2 we revert the D1 change such
-- that it is no longer in the diff, we need to still be able to apply D1 so we
-- can get it back to the state that is in this PR.  So, for each pull request,
-- find all of the work manifests associated with that pull request, but that
-- have different base/sha's, and then find all of the dirs they were run on,
-- and only those that are applies.
pull_request_applies_previous_commits as (
    select distinct
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        gwmds.path as path,
        gwmds.workspace as workspace
    from github_pull_requests as gpr
    inner join github_work_manifests as gwm
        on gpr.repository = gwm.repository and gpr.pull_number = gwm.pull_number
    inner join work_manifest_dirspaceflows as gwmds
        on gwmds.work_manifest = gwm.id
    left join github_pull_request_latest_unlocks as gpru
        on gpru.repository = gpr.repository and gpru.pull_number = gpr.pull_number
    where gwm.repository = $repository
          and gwm.pull_number = $pull_number
          and (gpr.base_sha <> gwm.base_sha or gpr.sha <> gwm.sha)
          and gwm.run_type in ('apply', 'autoapply', 'unsafe-apply')
          and (gpru.unlocked_at is null or gpru.unlocked_at < gwm.created_at)
),
-- Combine the dirspaces for the current revision with the dirspaces that have
-- been applied in previous revisions.
all_necessary_dirspaces as materialized (
    select distinct
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        coalesce(gds.path, prapc.path) as path,
        coalesce(gds.workspace, prapc.workspace) as workspace,
        gds.lock_policy as lock_policy
    from github_pull_requests as gpr
    inner join github_change_dirspaces as gds
        on gds.repository = gpr.repository
           and gds.base_sha = gpr.base_sha
           and (gds.sha = gpr.sha or gds.sha = gpr.merged_sha)
    left join pull_request_applies_previous_commits as prapc
        on gpr.repository = prapc.repository and gpr.pull_number = prapc.pull_number
    where gpr.repository = $repository and gpr.pull_number = $pull_number
),
-- All those pull requests which are not unlocked that overlap with the
-- dirspaces we care about.
pull_requests_of_interest as (
    select
        gpr.repository as repository,
        gpr.pull_number as pull_number
    from github_pull_requests as gpr
    inner join github_change_dirspaces as gcds
        on gcds.repository = gcds.repository
           and gcds.base_sha = gpr.base_sha
           and gcds.sha = gpr.sha
           and gcds.path = any($dirs)
           and gcds.workspace = any($workspaces)
    left join github_pull_request_latest_unlocks as unlocks
        on unlocks.repository = gpr.repository
           and unlocks.pull_number = gpr.pull_number
    where gpr.repository = $repository
          and gpr.merged_at is null
          or (gpr.merged_at is not null
              and (unlocks.unlocked_at is null or unlocks.unlocked_at < gpr.merged_at))
),
-- All the work manifests that are not unlocked that are an apply and overlap
-- with the dirspace we care about.
work_manifests_of_interest as (
    select
        gwm.repository as repository,
        gwm.pull_number as pull_number
    from github_work_manifests as gwm
    inner join github_pull_requests as gpr
        on gpr.repository = gwm.repository
           and gpr.pull_number = gwm.pull_number
    inner join work_manifest_results as wmr
        on wmr.work_manifest = gwm.id
           and wmr.path = any($dirs)
           and wmr.workspace = any($workspaces)
    left join github_pull_request_latest_unlocks as unlocks
        on unlocks.repository = gwm.repository
           and unlocks.pull_number = gwm.pull_number
    where gwm.repository = $repository
          and gwm.run_type = 'apply'
          and (unlocks.unlocked_at is null or unlocks.unlocked_at < gwm.created_at)
    group by gwm.repository, gwm.pull_number
),
combined_pull_requests_of_interest as (
    select * from pull_requests_of_interest
    union
    select * from work_manifests_of_interest
),
-- Given the above two queries, now we have every pull request which we need to
-- investigate for if they are completed.
all_pull_requests_of_interest as (
    select distinct * from combined_pull_requests_of_interest
),
all_pull_request_dirspaces_of_interest as (
    select
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        gcds.path as path,
        gcds.workspace as workspace
    from all_pull_requests_of_interest as apri
    inner join github_pull_requests as gpr
        on apri.repository = gpr.repository
           and apri.pull_number = gpr.pull_number
    inner join github_change_dirspaces as gcds
        on gcds.repository = gpr.repository
           and gcds.base_sha = gpr.base_sha
           and gcds.sha = gpr.sha
),
all_work_manifest_dirspaces_of_interest as (
    select
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        wmr.path as path,
        wmr.workspace as workspace
    from all_pull_requests_of_interest as apri
    inner join github_work_manifests as gwm
        on gwm.repository = apri.repository
           and gwm.pull_number = apri.pull_number
    inner join work_manifest_results as wmr
        on wmr.work_manifest = gwm.id
),
combined_dirspaces_of_interest as (
    select * from all_pull_request_dirspaces_of_interest
    union
    select * from all_work_manifest_dirspaces_of_interest
),
-- For all pull requests that we know overlap with dirspaces we care about, this
-- contains all dirspaces those pull requests operate on.  For example, if we
-- care about DIR1 and a pull request operates on DIR1 and DIR2, this will
-- contain DIR1 and DIR2.
all_dirspaces_of_interest as (
    select distinct * from combined_dirspaces_of_interest
),
all_work_manifest_runs as (
    select distinct on (gwm.repository, gwm.pull_number, wmr.path, wmr.workspace)
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        wmr.path as path,
        wmr.workspace as workspace,
        gwm.id as work_manifest,
        wmr.success as success,
        gwm.run_type as run_type,
        (plans.has_changes is not null and plans.has_changes) as has_changes,
        gpr.merged_at is not null as is_merged
    from all_dirspaces_of_interest as adsi
    inner join github_pull_requests as gpr
        on gpr.repository = adsi.repository
           and gpr.pull_number = adsi.pull_number
    inner join github_work_manifests as gwm
        on gwm.repository = adsi.repository
           and gwm.pull_number = adsi.pull_number
           and gwm.state = 'completed'
    inner join work_manifest_results as wmr
        on wmr.work_manifest = gwm.id
           and wmr.path = adsi.path
           and wmr.workspace = adsi.workspace
    left join plans
        on plans.work_manifest = gwm.id
           and plans.path = wmr.path
           and plans.workspace = wmr.workspace
    left join github_pull_request_latest_unlocks as unlocks
        on unlocks.repository = adsi.repository
           and unlocks.pull_number = adsi.pull_number
    where (unlocks.unlocked_at is null or unlocks.unlocked_at < gwm.created_at)
          and ((gpr.merged_at is not null and gwm.run_type in ('autoplan', 'plan', 'autoapply', 'apply'))
               or (gpr.merged_at is null and gwm.run_type in ('autoapply', 'apply')))
    order by gwm.repository, gwm.pull_number, wmr.path, wmr.workspace, gwm.created_at desc
),
dangling_dirspaces as (
    select
      adsi.repository as repository,
      adsi.pull_number as pull_number,
      adsi.path as path,
      adsi.workspace as workspace
    from all_dirspaces_of_interest as adsi
    inner join github_pull_requests as gpr
        on gpr.repository = adsi.repository
           and gpr.pull_number = adsi.pull_number
    inner join all_necessary_dirspaces as ands
        on ands.path = adsi.path
           and ands.workspace = adsi.workspace
    left join all_work_manifest_runs as awmr
        on adsi.repository = awmr.repository
           and adsi.pull_number = awmr.pull_number
           and adsi.path = awmr.path
           and adsi.workspace = awmr.workspace
    where (gpr.merged_at is null
           and awmr.run_type in ('autoapply', 'apply')
           and ands.lock_policy in ('strict', 'apply'))
          or (gpr.merged_at is not null
              and (adsi.repository is null
                   or ((awmr.run_type is null and ands.lock_policy in ('strict', 'merge'))
                        or ((awmr.run_type in ('autoapply', 'apply') and not awmr.success)
                            or (awmr.run_type in ('autoplan', 'plan') and awmr.success and awmr.has_changes)))))
    group by adsi.repository, adsi.pull_number, adsi.path, adsi.workspace
)
select distinct on (adds.path, adds.workspace, adds.pull_number)
    adds.path as path,
    adds.workspace as workspace,
    gpr.base_branch as base_branch,
    gpr.branch as branch_name,
    gpr.base_sha as bash_hash,
    gpr.sha as hash,
    gpr.merged_sha as merged_hash,
    gpr.merged_at as merged_at,
    gpr.pull_number as id,
    gpr.state as state,
    gpr.title as title,
    gpr.username as username
from github_pull_requests as gpr
inner join dangling_dirspaces as adds
    on gpr.repository = adds.repository and gpr.pull_number = adds.pull_number
where gpr.repository = $repository
      and gpr.pull_number <> $pull_number
      and adds.path = any($dirs)
      and adds.workspace = any($workspaces)
order by adds.path, adds.workspace, adds.pull_number
