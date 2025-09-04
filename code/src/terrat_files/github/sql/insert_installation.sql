insert into github_installations (
    id,
    login,
    org,
    target_type,
    tier,
    sender
) values (
    $id,
    $login,
    $org,
    $target_type,
    $tier,
    $sender
)
