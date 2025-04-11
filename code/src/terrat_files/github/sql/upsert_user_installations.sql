insert into github_user_installations2 (
  user_id,
  installation_id
)
select * from unnest($user, $installation)
on conflict (user_id, installation_id) do nothing
