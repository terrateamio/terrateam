select aui.api_user_id, aui.name, aui.created_at::text
from api_user_installations as aui
inner join gitlab_user_installations2 as gui
    on gui.user_id = aui.api_user_id
    and gui.installation_id = aui.installation_id
where aui.installation_id = $installation_id
order by aui.created_at
limit 100
