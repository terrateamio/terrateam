select
  gi.access_token
from
  gitlab_installations gi
where gi.id = $installation_id
