with
latest_unlocks as (
    select repository, max(unlocked_at) as unlocked_at from github_drift_unlocks group by repository
)
select
    gwm.id,
    gir.owner,
    gir.name,
    gwm.state,
    gwm.run_type,
    to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    to_char(gwm.completed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    (not (latest_unlocks.repository is null or latest_unlocks.unlocked_at < gwm.created_at)) as unlocked
from github_drift_work_manifests as gdwm
inner join github_work_manifests as gwm
    on gdwm.work_manifest = gwm.id
inner join github_installation_repositories as gir
    on gir.id = gwm.repository
left join latest_unlocks
    on latest_unlocks.repository = gwm.repository
order by gwm.created_at desc
limit 10
