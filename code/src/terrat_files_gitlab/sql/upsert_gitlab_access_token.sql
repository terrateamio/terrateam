insert into gitlab_installations (
    id,
    access_token,
    access_token_updated_by,
    access_token_updated_at,
    name
)
values (
    $installation_id,
    $access_token,
    $access_token_updated_by,
    now(),
    $group_name
)
on conflict (id)
do update set
    access_token = $access_token,
    access_token_updated_by = $access_token_updated_by,
    access_token_updated_at = now(),
    name = $group_name;
