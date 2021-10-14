insert into installation_env_vars (
       installation_id,
       name,
       value,
       modified_time,
       modified_by,
       secret,
       is_file
)
values (
       $installation_id,
       $name,
       $value,
       now(),
       $modified_by,
       true,
       $is_file
)
on conflict (installation_id, name) do update set (
   value, modified_time, modified_by, secret, is_file
) = (excluded.value, excluded.modified_time, excluded.modified_by, excluded.secret, excluded.is_file)
