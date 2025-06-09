select
  user_id,
  email,
  name,
  avatar_url
from github_users2
where username = $username
