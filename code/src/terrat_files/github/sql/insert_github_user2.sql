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
) on conflict (username) do nothing
