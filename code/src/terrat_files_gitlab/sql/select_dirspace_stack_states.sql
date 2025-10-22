with
pr as (
    select
        gpr.repository,
        gpr.pull_number,
        gpr.base_sha,
        gpr.sha,
        gpr.merged_sha,
        gprm.core_id as pr_core_id,
        grm.core_id as repo_core_id
    from gitlab_pull_requests as gpr
    inner join gitlab_pull_requests_map as gprm
        on gprm.repository_id = gpr.repository and gprm.pull_number = gpr.pull_number
    inner join gitlab_repositories_map as grm
        on grm.repository_id = gpr.repository
    where gpr.repository = $repo_id and gpr.pull_number = $pull_number
),
work_manifests_all as (
    select
        gwm.id,
        gwm.state,
        gwm.run_type,
        gwm.repository,
        gwm.pull_number,
        wmr.path,
        wmr.workspace,
        wmr.success,
        row_number() over (partition by
                               gwm.repository,
                               gwm.pull_number,
                               wmr.path,
                               wmr.workspace
                           order by gwm.created_at desc) as rn
    from gitlab_work_manifests as gwm
    inner join work_manifest_results as wmr
        on wmr.work_manifest = gwm.id
    inner join pr
        on pr.repository = gwm.repository
           and pr.pull_number = gwm.pull_number
           and pr.base_sha = gwm.base_sha
           and (pr.sha = gwm.sha or pr.merged_sha = gwm.sha)
    left join gitlab_pull_request_latest_unlocks as lu
        on lu.repository = gwm.repository and lu.pull_number = gwm.pull_number
    where gwm.completed_at is not null and (lu.unlocked_at is null or lu.unlocked_at < gwm.created_at)
),
work_manifests as (
    select * from work_manifests_all where rn = 1
)
select
    cd.path,
    cd.workspace,
    (case
       when wm.id is null then 'plan_pending'
       when wm.run_type = 'apply' and not wm.success then 'apply_failed'
       when wm.run_type = 'apply' then 'apply_success'
       when wm.run_type = 'plan' and not wm.success then 'plan_failed'
       when wm.run_type = 'plan' then 'apply_pending'
       else 'plan_pending'
     end)
from change_dirspaces as cd
inner join pr
    on pr.repo_core_id = cd.repo and pr.base_sha = cd.base_sha and (pr.sha = cd.sha or pr.merged_sha = cd.sha)
left join work_manifests as wm
    on wm.repository = pr.repository
       and wm.pull_number = pr.pull_number
       and wm.path = cd.path
       and wm.workspace = cd.workspace
