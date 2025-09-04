with
all_installation_ids as (
    select t.id from unnest($installation_ids) as t(id)
    inner join github_installations as gi
        on gi.id = t.id
),
deleted as (
    delete from github_user_installations2
    where user_id = $user_id and not exists (select id from all_installation_ids)
),
inserted as (
    insert into github_user_installations2 (user_id, installation_id)
    select $user_id, id from all_installation_ids
    on conflict (user_id, installation_id) do nothing
)
select
    gi.id,
    gi.login,
    gi.state
from all_installation_ids as ai
inner join github_installations as gi
    on gi.id = ai.id
