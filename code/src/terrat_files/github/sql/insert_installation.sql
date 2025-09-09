insert into github_installations (
    id,
    login,
    org,
    target_type,
    tier,
    installed_by
) values (
    $id,
    $login,
    $org,
    $target_type,
    $tier,
    $installed_by
)
