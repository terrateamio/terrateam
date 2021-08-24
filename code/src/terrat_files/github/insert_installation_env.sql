insert into installation_env_vars (
       installation_id,
       name,
       value,
       modified_time,
       modified_by,
       secret
)
values (
       $installation_id,
       $name,
       $value,
       now(),
       $modified_by,
       false
)
on conflict (installation_id, name) do update set (
   value, modified_time, modified_by, secret
) = (excluded.value, excluded.modified_time, excluded.modified_by, excluded.secret)
