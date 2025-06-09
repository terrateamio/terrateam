update github_users2 set
  token = $token,
  expiration = $expiration,
  refresh_token = $refresh_token,
  refresh_expiration = $refresh_expiration
where user_id = $user_id
