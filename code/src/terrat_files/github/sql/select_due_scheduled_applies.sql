with chosen as (
    select
        sa.id,
        sa.repo,
        sa.pull_number,
        sa.tag_query,
        sa.scheduled_at,
        sa.created_by,
        gir.installation_id,
        grm.repository_id,
        gir.owner,
        gir.name
    from scheduled_applies as sa
    inner join github_repositories_map as grm
        on grm.core_id = sa.repo
    inner join github_installation_repositories as gir
        on gir.id = grm.repository_id
    inner join github_installations as gi
        on gi.id = gir.installation_id
    where sa.state = 'pending'
      and sa.scheduled_at <= now()
      and gi.state = 'installed'
    order by sa.scheduled_at
    limit 1
    for update of sa skip locked
),
updated as (
    update scheduled_applies
    set state = 'running'
    from chosen
    where scheduled_applies.id = chosen.id
    returning chosen.*
)
select
    id,
    installation_id,
    repository_id,
    owner,
    name,
    pull_number,
    tag_query,
    scheduled_at
from updated
