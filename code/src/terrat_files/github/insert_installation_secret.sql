insert into installation_env_vars (
       installation_id,
       name,
       value,
       session_key,
       nonce,
       modified_time,
       modified_by,
       secret,
       is_file
)
values (
       $installation_id,
       $name,
       $value,
       $session_key,
       $nonce,
       now(),
       $modified_by,
       true,
       $is_file
)
on conflict (installation_id, name) do update set (
   value, session_key, nonce, modified_time, modified_by, secret, is_file
) = (excluded.value,
     excluded.session_key,
     excluded.nonce,
     excluded.modified_time,
     excluded.modified_by,
     excluded.secret,
     excluded.is_file)
