with
pull_request_applies_previous_commits as (
    select distinct
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        gwmds.path as path,
        gwmds.workspace as workspace
    from gitlab_pull_requests as gpr
    inner join gitlab_work_manifests as gwm
        on gpr.repository = gwm.repository and gpr.pull_number = gwm.pull_number
    inner join work_manifest_dirspaceflows as gwmds
        on gwmds.work_manifest = gwm.id
    where (gpr.base_sha <> gwm.base_sha or gpr.sha <> gwm.sha)
          and gwm.run_type in ('apply', 'autoapply', 'unsafe-apply')
),
all_necessary_dirspaces as (
    select distinct
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        coalesce(gds.path, prapc.path) as path,
        coalesce(gds.workspace, prapc.workspace) as workspace
    from gitlab_pull_requests as gpr
    inner join gitlab_change_dirspaces as gds
        on gds.base_sha = gpr.base_sha and (gds.sha = gpr.sha or gds.sha = gpr.merged_sha)
    left join pull_request_applies_previous_commits as prapc
        on gpr.repository = prapc.repository and gpr.pull_number = prapc.pull_number
),
work_manifest_results as (
    select
        gwm.id as id,
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        gwm.base_sha as base_sha,
        gwm.sha as sha,
        gwm.run_type as run_type,
        gwmr.path as path,
        gwmr.workspace as workspace,
        gwmr.success as success,
        row_number() over (partition by
                               gwm.repository,
                               gwmr.path,
                               gwmr.workspace
                           order by gwm.completed_at desc) as rn
    from gitlab_work_manifests as gwm
    inner join work_manifest_results as gwmr
        on gwmr.work_manifest = gwm.id
),
applied_dirspaces as (
    select distinct
        gpr.repository as repository,
        gpr.pull_number as pull_number,
        results.path as path,
        results.workspace as workspace
    from gitlab_pull_requests as gpr
    left join work_manifest_results as results
        on results.repository = gpr.repository and results.pull_number = gpr.pull_number
           and results.base_sha = gpr.base_sha
           and (results.sha = gpr.sha or results.sha = gpr.merged_sha)
    where results.rn = 1 and results.run_type in ('apply', 'autoapply', 'unsafe-apply') and results.success
)
select distinct
    ands.path,
    ands.workspace
from gitlab_pull_requests as gpr
inner join gitlab_installation_repositories as gir
    on gir.id = gpr.repository
inner join all_necessary_dirspaces as ands
    on ands.repository = gpr.repository and ands.pull_number = gpr.pull_number
left join applied_dirspaces as applied
    on ands.repository = applied.repository and ands.pull_number = applied.pull_number
       and ands.path = applied.path and ands.workspace = applied.workspace
where gpr.repository = $repo_id and gpr.pull_number = $pull_number and applied.repository is null
