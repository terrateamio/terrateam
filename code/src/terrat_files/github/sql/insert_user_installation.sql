insert into github_user_installations2 (user_id, installation_id)
values ($user_id, $installation_id)
on conflict do nothing
