with
dirspaces as (
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
all_necessary_dirspaces as (
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
overlapping_pull_requests as (
    select
        gpr.repository as repository,
        gpr.pull_number as pull_number
    from github_pull_requests as gpr
    inner join github_change_dirspaces as gcds
        on gcds.repository = gpr.repository
           and gcds.base_sha = gpr.base_sha
           and gcds.sha = gpr.sha
    inner join all_necessary_dirspaces as ands
        on ands.path = gcds.path
           and ands.workspace = gcds.workspace
    where gpr.repository = $repository and not gpr.all_dirspaces_applied
    group by gpr.repository, gpr.pull_number
),
-- This query does the heavy lifting.
--
-- Given a list of pull requests which we know have changes which overlap our
-- pull request, we want to:
--
-- 1. Find dirspaces associated with merged pull requests that either do not
-- have a work manifest associated or any work manifests for those dirspaces.
--
-- 2. Find all dirspaces for pull requests that have not been merged but have an
-- apply.
dirspace_ops_for_pull_requests as (
    select
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        gpr.merged_at is not null as is_merged,
        ands.path as path,
        ands.workspace as workspace,
        gwm.run_type as run_type,
        (plans.has_changes is not null and plans.has_changes) as has_changes,
        wmr.success as success,
        ands.lock_policy as lock_policy,
        row_number() over (partition by gpr.repository,
                                        gpr.pull_number,
                                        ands.path,
                                        ands.workspace
                           order by gwm.created_at desc) as rn
-- We want access to all the information in the pull request table, so select it
-- and then narrow it to over our overlapping pull requests.
    from github_pull_requests as gpr
    inner join overlapping_pull_requests as opr
        on opr.repository = gpr.repository
           and opr.pull_number = gpr.pull_number
-- We want the work manifests that ran against the overlapping PR
    left join github_work_manifests as gwm
        on gwm.repository = gpr.repository
           and gwm.pull_number = gpr.pull_number
-- The change dirspaces table contains the list of dirspaces in a specific
-- change (defined by the head sha and the sha it will be merged into).  So this
-- join tells us every dirspace that was in a change that has a work manifest
-- run on it EVEN IF that specific dirspace was not run.  So if we ran a work
-- manifest for dir DIR1, and the change also had DIR2 in it, we will see that
-- the pull request impacted DIR1 and DIR2.  This is important because if we
-- applied DIR1, then that means DIR2 is also locked even though we didn't run a
-- work manifest for DIR2.
--
-- It also gets any change dirspaces for the shas for the pull request.  This is
-- so we also find those dirspaces that have no runs associated at all, just a
-- pull request that was merged.
    inner join github_change_dirspaces as gcds
        on (gcds.repository = gwm.repository
            and gcds.base_sha = gwm.base_sha)
           or (gcds.repository = gpr.repository
               and gcds.base_sha = gpr.base_sha
               and gcds.sha = gpr.sha)
-- And then narrow that list of changed dirspaces to the ones we are interested
-- in.  So if we are interested in DIR2, but only DIR1 had a work manifest, the
-- above query will get use DIR1 and DIR2 and then this inner join will narrow
-- us back down to DIR2, the one we care about.
    inner join all_necessary_dirspaces as ands
        on ands.path = gcds.path
           and ands.workspace = gcds.workspace
-- And we also will nee to know for those work manifests that were run, whether
-- or not the specific dirspaces succeeded or not.
    left join work_manifest_results as wmr
        on wmr.work_manifest = gwm.id
           and wmr.path = gcds.path
           and wmr.workspace = gcds.workspace
-- And then also if they have plans, whether or not those plans had changes or not.
    left join plans
        on plans.work_manifest = gwm.id
           and plans.path = wmr.path
           and plans.workspace = wmr.workspace
-- And of course, if any unlocks happened, that invalidated the work manifest.
    left join github_pull_request_latest_unlocks as unlocks
        on unlocks.repository = gpr.repository
           and unlocks.pull_number = gpr.pull_number
-- This check for repository is not strictly necessary, but just adding it to be
-- explicit.
    where gpr.repository = $repository
-- If the pull request IS MERGED and it has not been unlocked since then, we
-- want to collect all plan and apply operations.
          and ((gpr.merged_at is not null
                and (unlocks.unlocked_at is null or unlocks.unlocked_at < gpr.merged_at)
-- If there are no work manifest runs then collect that row too
                and (gwm.id is null
                     or (gwm.state = 'completed'
                         and (unlocks.unlocked_at is null or unlocks.unlocked_at < gwm.created_at)
                         and (gwm.run_type in ('autoapply', 'apply', 'autoplan', 'plan')))))
-- If the pull request is NOT MERGED, then we are only interested in applies,
               or (gpr.merged_at is null
                   and gwm.id is not null
                   and (unlocks.unlocked_at is null or unlocks.unlocked_at < gwm.created_at)
                   and gwm.run_type in ('autoapply', 'apply')
                   and gwm.sha = gcds.sha))
),
-- At this point we have a set of values containing all of the runs for each
-- dirspace we care about.
--
-- A dangling dirspace is one where the pull request IS NOT MERGED but there is an apply for it.
--
-- OR
--
-- The pull request IS MERGED and there is either no work manifest associated
-- with it or any runs did not succeed.
--
-- Take the lock policy into account as well.
dangling_dirspaces as (
    select
        *
    from dirspace_ops_for_pull_requests as dopr
    where dopr.rn = 1
          and ((not is_merged
                and run_type in ('autoapply', 'apply')
                and lock_policy in ('strict', 'apply'))
               or (is_merged
                   and ((run_type is null and lock_policy in ('strict', 'merge'))
                        or ((run_type in ('autoapply', 'apply') and not success)
                             or (run_type in ('autoplan', 'plan') and success and has_changes)))))
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
inner join dirspaces as ds on adds.path = ds.dir and adds.workspace = ds.workspace
where gpr.repository = $repository and gpr.pull_number <> $pull_number
order by adds.path, adds.workspace, adds.pull_number
