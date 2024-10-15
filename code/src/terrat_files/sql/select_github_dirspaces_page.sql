with
unified_run_types as (
    select
       id,
       (case gwm.run_type
           when 'autoapply' then 'apply'
           when 'apply' then 'apply'
           when 'unsafe-apply' then 'apply'
           when 'autoplan' then 'plan'
           when 'plan' then 'plan'
           when 'index' then 'index'
           when 'build-config' then 'build-config'
           end) as run_type
    from github_work_manifests as gwm
),
latest_unlocks as (
    select
        repository,
        pull_number,
        max(unlocked_at) as unlocked_at
    from github_pull_request_unlocks
    group by repository, pull_number
),
latest_drift_unlocks as (
    select
        repository,
        max(unlocked_at) as unlocked_at
    from github_drift_unlocks
    group by repository
),
q as (
    select
        gwm.id as id,
        gwmds.path as dir,
        gwmds.workspace as workspace,
        gwm.base_sha as base_ref,
        (case
         when completed_at is not null then completed_at
         when (gdwm.work_manifest is null
               and lu.unlocked_at is not null
               and gwm.created_at <= lu.unlocked_at) then lu.unlocked_at
         when (gdwm.work_manifest is not null
               and ldu.unlocked_at is not null
               and gwm.created_at <= ldu.unlocked_at) then ldu.unlocked_at
        else null
        end) as completed_at,
        created_at,
        gwm.sha as branch_ref,
        gwm.run_type as run_type,
        (case
         when gwmr.success then 'success'
         when not gwmr.success then 'failure'
         when (gdwm.work_manifest is null
               and lu.unlocked_at is not null
               and gwm.created_at <= lu.unlocked_at) then 'aborted'
         when (gdwm.work_manifest is not null
               and ldu.unlocked_at is not null
               and gwm.created_at <= ldu.unlocked_at) then 'aborted'
         when gwm.state in ('running', 'queued', 'aborted') then gwm.state
         else 'unknown'
         end) as state,
        gwm.tag_query as tag_query,
        gwm.repository as repository,
        gwm.pull_number as pull_number,
        coalesce(gpr.base_branch, gdwm.branch) as base_branch,
        gir.owner as owner,
        gir.name as name,
        gwm.run_kind as kind,
        gpr.title as title,
        coalesce(gdwm.branch, gpr.branch) as branch,
        gwm.username as username,
        gwm.run_id as run_id,
        urt.run_type as unified_run_type,
        gwm.environment as environment
    from github_work_manifests as gwm
    inner join github_work_manifest_dirspaceflows as gwmds
        on gwmds.work_manifest = gwm.id
    inner join github_installation_repositories as gir
        on gir.id = gwm.repository
    inner join github_user_installations as gui
        on gir.installation_id = gui.installation_id
    inner join unified_run_types as urt
        on urt.id = gwm.id
    left join github_work_manifest_results as gwmr
        on gwm.id = gwmr.work_manifest and gwmds.path = gwmr.path and gwmds.workspace = gwmr.workspace
    left join github_pull_requests as gpr
        on gwm.repository = gpr.repository and gwm.pull_number = gpr.pull_number
    left join github_drift_work_manifests as gdwm
        on gwm.id = gdwm.work_manifest
    left join latest_unlocks as lu
        on lu.repository = gwm.repository and lu.pull_number = gwm.pull_number
    left join latest_drift_unlocks as ldu
        on ldu.repository = gwm.repository
    where gir.installation_id = $installation_id
          and gui.user_id = $user
)
select
    id,
    dir,
    workspace,
    base_ref,
    branch_ref,
    to_char(gwm.completed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as completed_at,
    to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
    unified_run_type,
    state,
    tag_query,
    pull_number,
    base_branch,
    owner,
    name,
    kind,
    title,
    branch,
    username,
    run_id,
    environment
from q as gwm
{{where}}
