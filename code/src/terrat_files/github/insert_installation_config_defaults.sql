insert into installation_config (
       installation_id,
       updated_at,
       updated_by
)
values (
       $installation_id,
       now(),
       $user_id
)
on conflict (installation_id) do update set (
   updated_at,
   updated_by
) = (
  excluded.updated_at,
  excluded.updated_by
)
