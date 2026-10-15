-- A registration of a kind updates the existing row of that kind whose data matches, and adds a
-- row when no row matches. Rows are keyed on kind AND data, so one kind can hold many rows (one
-- per state: data = {"state_id": ...}) and re-registering a kind never overwrites rows keyed to
-- other data. last_run_at is not touched, so every row keeps its own staggered next run time.
with updated as (
  update schedules set schedule = $schedule
  where kind = $kind and data = $data::jsonb
  returning id
)
insert into schedules (kind, schedule, data)
  select $kind, $schedule, $data
  where not exists (select 1 from updated)
