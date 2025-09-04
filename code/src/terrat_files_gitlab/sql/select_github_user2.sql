select
  user_id,
  email,
  name,
  avatar_url
from gitlab_users2
where username = $username
