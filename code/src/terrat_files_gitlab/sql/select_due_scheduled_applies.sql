with chosen as (
    select
        sa.id,
        sa.repo,
        sa.pull_number,
        sa.tag_query,
        sa.scheduled_at,
        sa.created_by,
        glr.installation_id,
        glr.id as repository_id,
        glr.owner,
        glr.name
    from scheduled_applies as sa
    inner join gitlab_repositories_map as glrm
        on glrm.core_id = sa.repo
    inner join gitlab_installation_repositories as glr
        on glr.id = glrm.repository_id
    inner join gitlab_installations as gli
        on gli.id = glr.installation_id
    where sa.state = 'pending'
      and sa.scheduled_at <= now()
      and gli.state = 'installed'
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
