select
  username,
  email,
  name,
  avatar_url
from github_users2
where user_id = $user_id
