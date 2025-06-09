select
        gir.id as id,
        gir.installation_id as installation_id,
        gir.name as name,
        to_char(updated_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') as updated_at,
        gir.setup as setup
from github_installation_repositories as gir
inner join github_user_installations2 as gui
      on gir.installation_id = gui.installation_id
where gui.user_id = $user_id and gui.installation_id = $installation_id
