select
  username,
  email,
  name,
  avatar_url
from gitlab_users2
where user_id = $user_id
