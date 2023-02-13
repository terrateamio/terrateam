select
    gwm.id,
    gir.owner,
    gir.name,
    gwm.state,
    gwm.run_type,
    to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    to_char(gwm.completed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
from github_drift_work_manifests as gdwm
inner join github_work_manifests as gwm
    on gdwm.work_manifest = gwm.id
inner join github_installation_repositories as gir
    on gir.id = gwm.repository
order by gwm.created_at desc
limit 10
