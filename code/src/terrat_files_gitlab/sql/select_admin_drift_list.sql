-- This is actually for both gitlab and gitlab
-- However this is not a pubic facing endpoint so it can be a little dirty
with
gitlab_drifts as (
    select
        gwm.id as id,
        gwm.repo_owner as owner,
        gwm.repo_name as name,
        gwm.state as state,
        gwm.run_type as runu_type,
        to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
        to_char(gwm.completed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as completed_at,
        (latest_unlocks.repository is null or gwm.created_at < latest_unlocks.unlocked_at) as unlocked
    from drift_work_manifests as gdwm
    inner join gitlab_work_manifests as gwm
        on gdwm.work_manifest = gwm.id
    left join gitlab_drift_latest_unlocks as latest_unlocks
        on latest_unlocks.repository = gwm.repository
    order by gwm.created_at desc
    limit 10
),
gitlab_drifts as (
    select
        gwm.id as id,
        gwm.repo_owner as owner,
        gwm.repo_name as name,
        gwm.state as state,
        gwm.run_type as runu_type,
        to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
        to_char(gwm.completed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as completed_at,
        (latest_unlocks.repository is null or gwm.created_at < latest_unlocks.unlocked_at) as unlocked
    from drift_work_manifests as gdwm
    inner join gitlab_work_manifests as gwm
        on gdwm.work_manifest = gwm.id
    left join gitlab_drift_latest_unlocks as latest_unlocks
        on latest_unlocks.repository = gwm.repository
    order by gwm.created_at desc
    limit 10
)
select * from gitlab_drifts
union
select * from gitlab_drifts
