delete from users2
where id = $api_user_id
and type = 'api'
and id in (
    select api_user_id from api_user_installations
    where installation_id = $installation_id
)
