update github_users set
       token = $token,
       refresh_token = $refresh_token,
       expiration = $expiration,
       refresh_expiration = $refresh_expiration
where user_id = $user_id
