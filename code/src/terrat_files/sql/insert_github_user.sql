insert into github_users (
    id,
    user_id,
    token,
    expiration,
    refresh_token,
    refresh_expiration
) values (
    $id,
    $user_id,
    $token,
    $expiration,
    $refresh_token,
    $refresh_expiration
)
