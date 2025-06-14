select
  username,
  email,
  name,
  avatar_url,
  gitlab_user_id
from gitlab_users2
where user_id = $user_id
