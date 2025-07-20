with
--- In the case that the pull request being evaluated here is merged, we want to
--- use the SHA information of the most recently merged pull request (because
--- the work manifest will run against the latest sha).
latest_merged_pull_request as (
    select
        jc.repo as repo,
        gpr.pull_number,
        gpr.merged_sha
    from job_contexts as jc
    inner join github_repositories_map as grm
      on jc.repo = grm.core_id
    inner join github_pull_requests as gpr
      on gpr.repository = grm.repository_id
    where gpr.state = 'merged'
    order by gpr.merged_at desc
    limit 1
),
context as (
  select
    jc.id,
    grm.repository_id as repo,
    gprm.pull_number as pull_number,
    coalesce(gpr.branch, jc.params->>'branch') as branch,
    coalesce(gpr.base_branch, jc.params->>'dest_branch') as dest_branch,
    coalesce(gpr.sha, bh.hash) as branch_hash,
    coalesce(gpr.base_sha, dbh.hash) as dest_branch_hash,
    gpr.merged_sha,
    lmpr.merged_sha as latest_merged_sha
  from job_contexts as jc
  inner join github_repositories_map as grm
    on grm.core_id = jc.repo
  left join github_pull_requests_map as gprm
    on gprm.core_id = (jc.params->>'pull_request')::uuid
  left join github_pull_requests as gpr
    on gpr.repository = gprm.repository_id and gpr.pull_number = gprm.pull_number
  inner join branch_commit_hashes as bh
    on bh.repo = jc.repo and bh.branch = coalesce(gpr.branch, jc.params->>'branch')
  inner join branch_commit_hashes as dbh
    on dbh.repo = jc.repo and dbh.branch = coalesce(gpr.base_branch, jc.params->>'dest_branch', jc.params->>'branch')
  left join latest_merged_pull_request as lmpr
    on jc.repo = lmpr.repo
  where jc.id = $context_id
),
jobs as (
  select
    jobs.*
  from jobs
  inner join context as jc
    on jc.id = jobs.context_id
  where jobs.context_id = jc.id
),
wm as (
  select
        wm.id as id,
        wm.repository as repository,
        wm.pull_number as pull_number,
        wm.base_sha as base_sha,
        wm.sha as sha,
        wm.created_at as created_at,
        (case
           when wm.run_type in ('autoapply', 'apply', 'unsafe-apply') then 'apply'
           when wm.run_type in ('autoplan', 'plan') then 'plan'
           else wm.run_type
         end) as run_type
  from github_work_manifests as wm
  inner join context as c
    on c.repo = wm.repository
       and c.dest_branch_hash = wm.base_sha
       and (c.branch_hash = wm.sha
            or c.merged_sha is not distinct from wm.sha
            or c.latest_merged_sha is not distinct from wm.sha)
  inner join job_work_manifests as jwm
    on jwm.work_manifest = wm.id
  inner join jobs
    on jwm.job_id = jobs.id
  left join github_pull_request_latest_unlocks as unlocks
    on unlocks.repository = wm.repository and unlocks.pull_number = wm.pull_number
  left join github_drift_latest_unlocks as drift_unlocks
    on drift_unlocks.repository = wm.repository
  where (c.pull_number is not distinct from wm.pull_number)
        and ((jobs.params->'kind' is null
              and (unlocks.unlocked_at is null or unlocks.unlocked_at < wm.created_at))
             or (jobs.params->'kind'->>'type' = 'drift'
                 and (drift_unlocks.unlocked_at is null or drift_unlocks.unlocked_at < wm.created_at)))
),
work_manifest_results as (
  select
      wm.id as work_manifest,
      wm.repository as repository,
      wm.pull_number as pull_number,
      wm.base_sha as base_sha,
      wm.sha as sha,
      wm.run_type as run_type,
      wmr.path as path,
      wmr.workspace as workspace,
      wmr.success as success,
      row_number() over (partition by
                             wmr.path,
                             wmr.workspace
                         order by wm.created_at desc) as rn
  from wm
  inner join work_manifest_results as wmr
    on wmr.work_manifest = wm.id
  order by wm.created_at desc
),
plans_with_no_changes as (
  select
    wmr.path,
    wmr.workspace
  from work_manifest_results as wmr
  inner join plans
    on plans.work_manifest = wmr.work_manifest
       and plans.path = wmr.path
       and plans.workspace = wmr.workspace
  where wmr.rn = 1 and wmr.success and not plans.has_changes
)
select
  wmr.path,
  wmr.workspace
from work_manifest_results as wmr
inner join wm
  on wmr.work_manifest = wm.id
left join plans_with_no_changes as pwnc
  on pwnc.path = wmr.path
     and pwnc.workspace = wmr.workspace
where wmr.rn = 1
      and wmr.success
      and (pwnc.path is not null or wm.run_type = 'apply')
