select
        to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        user_agent
from user_sessions
where user_id = $user_id
order by created_at
