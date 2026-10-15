select id,
       schedule,
       kind,
       data
from schedules
where id = $id
