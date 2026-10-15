-- Counted here: returning every deleted key just to count it would ship the whole
-- backlog back on the first run.
with
deleted as (
    delete from oauth2_sessions
    where expires_at < now()
    returning 1
)
select count(*)
from deleted
