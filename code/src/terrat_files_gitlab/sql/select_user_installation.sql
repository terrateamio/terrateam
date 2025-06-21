select
  installation_id
from gitlab_user_installations
where user_id = $user_id and installation_id = $installation_id
