select
  installation_id
from github_user_installations2
where user_id = $user_id and installation_id = $installation_id
