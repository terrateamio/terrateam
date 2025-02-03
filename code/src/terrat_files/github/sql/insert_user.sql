insert into users (
    email,
    name,
    org,
    avatar_url
) values (
    $email,
    $name,
    $org,
    $avatar_url
) returning id
