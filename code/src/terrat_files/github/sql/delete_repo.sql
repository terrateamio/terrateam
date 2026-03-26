with
repo as (
    select grm.core_id
    from github_repositories_map as grm
    inner join github_installation_repositories as gir
        on gir.id = grm.repository_id
    where grm.repository_id = $repo_id
        and gir.installation_id = $installation_id
),
pull_requests as (
    select gprm.core_id
    from github_pull_requests_map as gprm
    inner join github_installation_repositories as gir
        on gir.id = gprm.repository_id
    where gprm.repository_id = $repo_id
        and gir.installation_id = $installation_id
),
delete_work_manifest_comments as (
    delete from github_work_manifest_comments
    using github_installation_repositories as gir
    where github_work_manifest_comments.repository = gir.id
        and gir.id = $repo_id
        and gir.installation_id = $installation_id
),
delete_plans as (
    delete from plans
    using work_manifests as wm, repo as r
    where plans.work_manifest = wm.id and wm.repo = r.core_id
),
delete_workflow_step_outputs as (
    delete from workflow_step_outputs
    using work_manifests as wm, repo as r
    where workflow_step_outputs.work_manifest = wm.id and wm.repo = r.core_id
),
delete_work_manifest_results as (
    delete from work_manifest_results
    using work_manifests as wm, repo as r
    where work_manifest_results.work_manifest = wm.id and wm.repo = r.core_id
),
delete_work_manifest_dirspaceflows as (
    delete from work_manifest_dirspaceflows
    using work_manifests as wm, repo as r
    where work_manifest_dirspaceflows.work_manifest = wm.id and wm.repo = r.core_id
),
delete_work_manifest_access_control as (
    delete from work_manifest_access_control_denied_dirspaces
    using work_manifests as wm, repo as r
    where work_manifest_access_control_denied_dirspaces.work_manifest = wm.id and wm.repo = r.core_id
),
delete_work_manifest_steps as (
    delete from work_manifest_steps
    using work_manifests as wm, repo as r
    where work_manifest_steps.work_manifest_id = wm.id and wm.repo = r.core_id
),
delete_flow_states as (
    delete from flow_states
    using work_manifests as wm, repo as r
    where flow_states.id = wm.id and wm.repo = r.core_id
),
delete_pull_request_stacks as (
    delete from pull_request_stacks
    using pull_requests as pr
    where pull_request_stacks.pull_request = pr.core_id
),
delete_gates as (
    delete from gates
    using pull_requests as pr
    where gates.pull_request = pr.core_id
),
delete_gate_approvals as (
    delete from gate_approvals
    using pull_requests as pr
    where gate_approvals.pull_request = pr.core_id
),
delete_dirspace_pull_request_locks as (
    delete from dirspace_pull_request_locks
    using pull_requests as pr
    where dirspace_pull_request_locks.pull_request = pr.core_id
),
delete_pull_request_unlocks as (
    delete from pull_request_unlocks
    using pull_requests as pr
    where pull_request_unlocks.pull_request = pr.core_id
),
delete_job_work_manifests as (
    delete from job_work_manifests
    using work_manifests as wm, repo as r
    where job_work_manifests.work_manifest = wm.id and wm.repo = r.core_id
),
delete_jobs as (
    delete from jobs
    using job_contexts as jc, repo as r
    where jobs.context_id = jc.id and jc.repo = r.core_id
),
delete_job_contexts as (
    delete from job_contexts
    using repo as r
    where job_contexts.repo = r.core_id
),
delete_drift_work_manifests as (
    delete from drift_work_manifests
    using work_manifests as wm, repo as r
    where drift_work_manifests.work_manifest = wm.id and wm.repo = r.core_id
),
delete_index_work_manifests as (
    delete from index_work_manifests
    using work_manifests as wm, repo as r
    where index_work_manifests.work_manifest = wm.id and wm.repo = r.core_id
),
delete_compute_node_work as (
    delete from compute_node_work
    using work_manifests as wm, repo as r
    where compute_node_work.work_manifest = wm.id and wm.repo = r.core_id
),
delete_work_manifests as (
    delete from work_manifests
    using repo as r
    where work_manifests.repo = r.core_id
),
delete_branch_commit_hashes as (
    delete from branch_commit_hashes
    using repo as r
    where branch_commit_hashes.repo = r.core_id
),
delete_change_dirspaces as (
    delete from change_dirspaces
    using repo as r
    where change_dirspaces.repo = r.core_id
),
delete_drift_schedules as (
    delete from drift_schedules
    using repo as r
    where drift_schedules.repo = r.core_id
),
delete_drift_unlocks as (
    delete from drift_unlocks
    using repo as r
    where drift_unlocks.repo = r.core_id
),
delete_pull_requests_map as (
    delete from github_pull_requests_map
    using github_installation_repositories as gir
    where github_pull_requests_map.repository_id = gir.id
        and gir.id = $repo_id
        and gir.installation_id = $installation_id
),
delete_pull_requests as (
    delete from github_pull_requests
    using github_installation_repositories as gir
    where github_pull_requests.repository = gir.id
        and gir.id = $repo_id
        and gir.installation_id = $installation_id
),
delete_repositories_map as (
    delete from github_repositories_map
    using github_installation_repositories as gir
    where github_repositories_map.repository_id = gir.id
        and gir.id = $repo_id
        and gir.installation_id = $installation_id
)
delete from github_installation_repositories
where id = $repo_id and installation_id = $installation_id
