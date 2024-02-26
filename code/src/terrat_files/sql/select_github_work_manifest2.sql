select
    gwm.base_sha,
    to_char(gwm.completed_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as completed_at,
    to_char(gwm.created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as created_at,
    gwm.pull_number,
    gwm.repository,
    gwm.run_id,
    gwm.run_type,
    gwm.sha,
    gwm.state,
    gwm.tag_query,
    gwm.username,
    gwm.run_kind,
    gir.installation_id,
    gir.id,
    gir.owner,
    gir.name
from github_work_manifests as gwm
inner join github_installation_repositories as gir
  on gir.id = gwm.repository
where gwm.id = $id
