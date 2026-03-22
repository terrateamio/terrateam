select login, target_type
from github_installations
where id = $installation_id
