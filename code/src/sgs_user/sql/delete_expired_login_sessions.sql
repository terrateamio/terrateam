-- Counted here: returning every deleted id just to count it would ship the whole
-- backlog back on the first run.
with
deleted as (
    delete from access_tokens
    where kind = 'login'
      and expiration is not null
      and expiration < now()
    returning 1
)
select count(*)
from deleted
