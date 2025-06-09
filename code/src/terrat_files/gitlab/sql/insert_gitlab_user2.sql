insert into github_users2 (
  avatar_url,
  email,
  expiration,
  name,
  refresh_expiration,
  refresh_token,
  token,
  user_id,
  username
) VALUES (
  $avatar_url,
  $email,
  $expiration,
  $name,
  $refresh_expiration,
  $refresh_token,
  $token,
  $user_id,
  $username
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
  
