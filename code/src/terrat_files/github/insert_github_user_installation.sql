insert into github_user_installations (
       user_id,
       installation_id,
       expiration,
       admin
)
values (
       $user_id,
       $installation_id,
       $expiration,
       $admin
)
on conflict (user_id, installation_id) do update set (
expiration, admin) = (excluded.expiration, excluded.admin)
