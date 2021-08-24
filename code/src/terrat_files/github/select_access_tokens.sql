select
        token,
        refresh_token,
        to_char(expiration, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        to_char(refresh_expiration, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
from github_users where user_id = $user_id
