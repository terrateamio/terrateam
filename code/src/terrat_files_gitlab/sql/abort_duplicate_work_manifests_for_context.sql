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
  inner join gitlab_repositories_map as grm
    on grm.core_id = jc.repo
  left join gitlab_pull_requests_map as gprm
    on gprm.core_id = (jc.params->>'pull_request')::uuid
  left join gitlab_pull_requests as gpr
    on gpr.repository = gprm.repository_id and gpr.pull_number = gprm.pull_number
  inner join branch_commit_hashes as bh
    on bh.repo = jc.repo and bh.branch = coalesce(gpr.branch, jc.params->>'branch')
  inner join branch_commit_hashes as dbh
    on dbh.repo = jc.repo and dbh.branch = coalesce(gpr.base_branch, jc.params->>'dest_branch', jc.params->>'branch')
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
dirspaces as (
    select dir, workspace from unnest($dirs, $workspaces) as v(dir, workspace)
),
work_manifests_for_dirspace as (
    select distinct
        gwm.id
    from gitlab_work_manifests as gwm
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
)
update work_manifests
set state = 'aborted', completed_at = now()
from work_manifests_for_dirspace
where work_manifests.id = work_manifests_for_dirspace.id
returning work_manifests.id
