select
  token,
  (expiration < now()),
  refresh_token
from github_users2
where user_id = $user_id
