-- Given a work manifest id, determine the action that should be performed with
-- each directory/workspace it.  Possible action, per directory:
--
-- RUN - All prerequisites to run this directory/workspace passed.
--
-- EXISTING_PARTIAL_APPLIES - If the run is an apply, cannot run this
-- directory/workspace because there are existing runs for different
-- base_sha/sha combination that is incomplete.
--
-- MISSING_PLAN - If the run is an apply, cannot run because of a missing
-- successful plan.
--
-- In order to RUN, any of the following must be true:
--
-- 1. The work manifest is a plan.
--
-- 2. The work manifest is an apply and the most recent operation on that
-- directory/workspace is a successful plan and the work manifest is the same
-- sha as the plan and there are no other pull requests that are locking the
-- repo (see below for the definition of locking).
--
-- A pull request locks a repository if it contains any applies
with
wm as (
    select * from github_work_manifests where id = $id
),
work_manifests as (
    select
        id,
        created_at,
        completed_at,
        sha,
        repository,
        pull_request,
        state,
        (case run_type
         when 'autoapply' then 'apply'
         when 'apply' then 'apply'
         when 'autoplan' then 'plan'
         when 'plan' then 'plan'
         end) as unified_run_type,
    from github_work_manifests
),
-- The result of each work manifest run grouped by path, workspace, and run type
run_results_for_repository as (
    select
        wms.sha as sha,
        wms.unified_run_type as unified_run_type,
        wms.pull_request as pull_request,
        rr.path as path,
        rr.workspace as workspace,
        row_number()
            over (partition by rr.path, rr.workspace, wms.unified_run_type
                  order by wms.completed_at desc) as rn
    from work_manifests as wms
    inner join wm on wms.repository = wm.repository
    inner join github_action_run_results as rr on wms.id = rr.work_manifest
    where wms.state in ('completed', 'failed')
),
-- The most recent result of each work manifest
latest_run_results_for_repository as (
    select * from run_results_for_repository where rn = 1
),
all_applied_change_dir_per_pull_request as (
    select pull_request, path, workspace
    from wm
    inner join work_manifests on work_manifests.repository = wm.repository
    inner join github_change_dirs as gcd on gcd.sha = work_manifests.sha
    
),
-- For all pull requests, this is the union of the change dirs for the sha of
-- the most recent work manifest as well as any applies that have happened in
-- that pull request
count_change_dirs_per_pull_request as (
    select pull_request, 
    from wm
    inner join 
),
change_counts as (
    select gcd.sha as sha, count(*) as change_count
    from github_change_dirs as gcd
    inner join wm on gcd.repository = wm.repository and gcd.sha = wm.sha
),
applied_change_counts as (
    select sha, count(*) as apply_count
    from latest_run_results_for_repository
    where unified_run_type = 'apply'
    group by sha
),
partially_applied_changes as (
    select sha
    from change_counts as cc
    inner join applied_change_counts as acc on acc.sha = cc.sha
    where acc.apply_count > 0 and acc.apply_count < cc.change_count
),
all_applied_dirs_per_pull_request as (
    select pull_request, sha, path, workspace
    from latest_run_results_for_repository
    group by 
),
dirs_with_plans as (
    select sha, path, workspace
)
