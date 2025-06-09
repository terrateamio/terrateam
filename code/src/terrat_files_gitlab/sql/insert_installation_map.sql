insert into gitlab_installations_map (installation_id)
values ($installation)
on conflict (installation_id) do nothing
