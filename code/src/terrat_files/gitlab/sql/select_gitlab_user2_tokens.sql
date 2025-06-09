select
  token,
  (expiration < now()),
  refresh_token
from gitlab_users2
where user_id = $user_id
