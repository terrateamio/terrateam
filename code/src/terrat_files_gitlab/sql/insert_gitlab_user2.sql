insert into gitlab_users2 (
  avatar_url,
  email,
  expiration,
  name,
  refresh_expiration,
  refresh_token,
  token,
  user_id,
  username,
  gitlab_user_id
) VALUES (
  $avatar_url,
  $email,
  $expiration,
  $name,
  $refresh_expiration,
  $refresh_token,
  $token,
  $user_id,
  $username,
  $gitlab_user_id
) on conflict (username) do update set (
  avatar_url,
  email,
  expiration,
  name,
  refresh_expiration,
  refresh_token,
  token
) = (
  excluded.avatar_url,
  excluded.email,
  excluded.expiration,
  excluded.name,
  excluded.refresh_expiration,
  excluded.refresh_token,
  excluded.token
)
  
