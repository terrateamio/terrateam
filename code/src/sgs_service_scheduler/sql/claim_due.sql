select id,
       schedule,
       kind,
       data
from schedules
where now() > last_run_at + (case schedule
        when 'minutely' then interval '1 minute'
        when 'hourly' then interval '1 hour'
        when 'daily' then interval '1 day'
        when 'weekly' then interval '7 days'
        when 'monthly' then interval '1 month'
    end)
order by last_run_at asc
limit 1
for update skip locked
