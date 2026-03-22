with new_user as (
    insert into users2 (type) values ('api') returning id
)
insert into api_user_installations (api_user_id, installation_id, name, created_by)
select id, $installation_id, $name, $created_by from new_user
returning api_user_id
