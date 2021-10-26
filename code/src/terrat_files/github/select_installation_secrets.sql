select
        name,
        value,
        session_key,
        nonce,
        is_file,
        modified_by,
        to_char(modified_time, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
from installation_env_vars
where installation_id = $installation_id and secret
order by name
