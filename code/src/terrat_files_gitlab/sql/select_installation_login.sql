select name, 'Organization' as target_type
from gitlab_installations
where id = $installation_id
