with
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
),
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
    inner join github_work_manifest_dirspaceflows as gwmds
        on gwmds.work_manifest = gwm.id
    left join latest_unlocks as gpru
        on gpru.repository = gpr.repository and gpru.pull_number = gpr.pull_number
    where (gpr.base_sha <> gwm.base_sha or gpr.sha <> gwm.sha)
          and gwm.run_type in ('apply', 'autoapply')
          and (gpru.unlocked_at is null or gpru.unlocked_at < gwm.created_at)
),
-- Combine the dirspaces for the current revision with the dirspaces that have
-- been applied in previous revisions.
all_necessary_dirspaces as (
    select distinct
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        coalesce(gds.path, prapc.path) as path,
        coalesce(gds.workspace, prapc.workspace) as workspace
    from github_pull_requests as gpr
    inner join github_dirspaces as gds
        on gds.base_sha = gpr.base_sha and (gds.sha = gpr.sha or gds.sha = gpr.merged_sha)
    left join pull_request_applies_previous_commits as prapc
        on gpr.repository = prapc.repository and gpr.pull_number = prapc.pull_number
),
unmerged_pull_requests_with_applies as (
    select distinct
        gpr.repository as repository,
        gpr.pull_number as pull_number
    from github_pull_requests as gpr
    inner join github_work_manifests as gwm
        on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
    left join latest_unlocks as gpru
        on gpru.repository = gpr.repository and gpru.pull_number = gpr.pull_number
    where gpr.state in ('open', 'closed') and gwm.run_type in ('apply', 'autoapply')
          and (gpru.unlocked_at is null or gpru.unlocked_at < gwm.created_at)
),
-- All those dirspaces that are in a pull request that has at least one apply
-- and not merged.
dangling_dirspaces as (
    select
        ands.repository as repository,
        ands.pull_number as pull_number,
        ands.path as path,
        ands.workspace as workspace
    from unmerged_pull_requests_with_applies as uprwa
    inner join all_necessary_dirspaces as ands
        on ands.repository = uprwa.repository and ands.pull_number = uprwa.pull_number
),
-- For all required dirspaces we will find only those pull requests which have
--  been merged and then of those merge applies we want those necessary
--  directories that do not appear in the merged list.
merged_pull_requests as (
    select
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        gpr.base_sha as base_sha,
        gpr.sha as sha,
        gpr.merged_sha as merged_sha
    from github_pull_requests as gpr
    left join latest_unlocks as unlocks
        on unlocks.repository = gpr.repository and unlocks.pull_number = gpr.pull_number
    where gpr.state = 'merged'
          and (unlocks.unlocked_at is null or unlocks.unlocked_at < gpr.merged_at)
),
applies_for_merged_pull_requests as (
    select distinct
        mpr.repository as repository,
        mpr.pull_number as pull_number,
        gwmds.path as path,
        gwmds.workspace as workspace
    from merged_pull_requests as mpr
    inner join github_work_manifests as gwm
        on mpr.repository = gwm.repository and mpr.pull_number = gwm.pull_number
           and gwm.base_sha = mpr.base_sha and (gwm.sha = mpr.sha or gwm.sha = mpr.merged_sha)
    inner join github_work_manifest_dirspaceflows as gwmds
        on gwmds.work_manifest = gwm.id
    inner join github_work_manifest_results as results
        on results.work_manifest = gwm.id
           and results.path = gwmds.path and results.workspace = gwmds.workspace
    where gwm.run_type in ('apply', 'autoapply') and results.success
),
unapplied_dirspaces as (
    select
        ands.repository as repository,
        ands.pull_number as pull_number,
        ands.path as path,
        ands.workspace as workspace
    from all_necessary_dirspaces as ands
    inner join merged_pull_requests as merged
        on merged.repository = ands.repository and merged.pull_number = ands.pull_number
    left join applies_for_merged_pull_requests as applies
        on applies.repository = ands.repository and applies.pull_number = ands.pull_number
           and applies.path = ands.path and applies.workspace = ands.workspace
    where applies.path is null
),
-- And now combine our two lists of dirspaces:
--
-- 1. The dirspaces that a merged PR needs to be applied but haven't.
--
-- 2. The dirspaces for any PRs that have not been merged but have applies.
all_dangling_dirspaces as (
    select distinct
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        coalesce(uds.path, dds.path) as path,
        coalesce(uds.workspace, dds.workspace) as workspace
    from github_pull_requests as gpr
    left join unapplied_dirspaces as uds
        on uds.repository = gpr.repository and uds.pull_number = gpr.pull_number
    left join dangling_dirspaces as dds
        on dds.repository = gpr.repository and dds.pull_number = gpr.pull_number
    where uds.repository is not null or dds.repository is not null
)
select
    adds.path as path,
    adds.workspace as workspace,
    gpr.base_branch as base_branch,
    gpr.branch as branch_name,
    gpr.base_sha as bash_hash,
    gpr.sha as hash,
    gpr.merged_sha as merged_hash,
    gpr.merged_at as merged_at,
    gpr.pull_number as id,
    gpr.state as state
from github_pull_requests as gpr
inner join all_dangling_dirspaces as adds
    on gpr.repository = adds.repository and gpr.pull_number = adds.pull_number
inner join dirspaces as ds on adds.path = ds.dir and adds.workspace = ds.workspace
where gpr.repository = $repository and gpr.pull_number <> $pull_number
