with
context as (
  select
    jc.id,
    grm.repository_id as repo,
    gprm.pull_number as pull_number,
    coalesce(gpr.branch, jc.params->>'branch') as branch,
    coalesce(gpr.base_branch, jc.params->>'dest_branch') as dest_branch,
    bh.hash as branch_hash,
    dbh.hash as dest_branch_hash,
    gpr.merged_sha
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
  where jc.id = $context_id
),
-- The job making the request.  Defined before the jobs CTE below so that it
-- reads the jobs table rather than that CTE.
cur_job as (
  select created_at from jobs where id = $job_id
),
-- Only jobs that predate the job making the request.  A job is not older than
-- itself, so this excludes aborting our own work manifests as well as those of
-- any job created after us: newer work supersedes older work, never the
-- reverse.
jobs as (
  select
    jobs.*
  from jobs
  inner join context as jc
    on jc.id = jobs.context_id
  where jobs.context_id = jc.id
        and jobs.created_at < (select created_at from cur_job)
),
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
),
-- The dirspaces that the pull request changes at its head now.
changed_dirspaces as (
    select dir, workspace
    from unnest($changed_dirs, $changed_workspaces) as v(dir, workspace)
),
work_manifests_for_dirspace as (
    select distinct
        gwm.id
    from github_work_manifests as gwm
    inner join job_work_manifests as jwm
      on jwm.work_manifest = gwm.id
    inner join jobs
      on jobs.id = jwm.job_id
    inner join context as c
      on c.id = jobs.context_id
    inner join work_manifest_dirspaceflows as gwmdsfs
        on gwmdsfs.work_manifest = gwm.id
    inner join dirspaces
        on dirspaces.dir = gwmdsfs.path and dirspaces.workspace = gwmdsfs.workspace
    where gwm.state in ('queued', 'running')
          and jobs.params->>'type' = 'plan'
          and $run_type in ('autoplan', 'plan')
-- Abort an older plan only when the new plan covers each of its dirspaces that
-- the pull request still changes.  The result of an aborted plan is stored and
-- not posted, thus a dirspace that the new plan does not plan would keep that
-- result as its newest plan, which the user did not see.  A dirspace that the
-- pull request no longer changes needs no plan, thus it does not keep the older
-- plan alive.  An older plan that is not covered runs, and the new plan waits
-- behind it on the dirspaces they share.
          and not exists (
            select 1
            from work_manifest_dirspaceflows as other
            where other.work_manifest = gwm.id
                  and not exists (
                    select 1
                    from dirspaces as d
                    where d.dir = other.path and d.workspace = other.workspace)
                  and exists (
                    select 1
                    from changed_dirspaces as c
                    where c.dir = other.path and c.workspace = other.workspace))
),
-- A work manifest that the dispatcher started and that has not called home
-- within the start timeout is stuck: its action run never started, or it died
-- before the first poll.  It stays running, thus it holds the dirspace locks of
-- its run and new work waits behind it with no end.  Abort it, silently, as the
-- abort of an older duplicate plan above is silent (RFD 2826).
--
-- Our own work manifests are spared, as the SELECT that follows this UPDATE
-- spares them: the work of this job is not a conflict with itself.  A work
-- manifest with no dispatch time is one of before the column existed, and it is
-- not stale.
stale_work_manifests as (
    select distinct
        gwm.id
    from github_work_manifests as gwm
-- The views do not carry the dispatch time, thus it comes from work_manifests.
    inner join work_manifests as core
        on core.id = gwm.id
    inner join work_manifest_dirspaceflows as gwmdsfs
        on gwmdsfs.work_manifest = gwm.id
    inner join dirspaces
        on dirspaces.dir = gwmdsfs.path and dirspaces.workspace = gwmdsfs.workspace
    inner join context as c
      on c.repo = gwm.repository
    where gwm.state = 'running'
          and gwm.run_id is null
          and now() - core.dispatched_at > make_interval(secs => $start_timeout)
          and not exists (select 1
                          from job_work_manifests as jwm
                          where jwm.work_manifest = gwm.id and jwm.job_id = $job_id)
),
work_manifests_to_abort as (
    select id from work_manifests_for_dirspace
    union
    select id from stale_work_manifests
)
update work_manifests
set state = 'aborted', completed_at = now()
from work_manifests_to_abort
where work_manifests.id = work_manifests_to_abort.id
returning work_manifests.id
