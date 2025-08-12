-- Kind of an awkward way to do an upsert but still get out inserted row back
-- even if it already exists.
with
attempted_insert as (
    insert into gitlab_installations (id, name) values($id, $name)
    on conflict (id) do nothing
    returning webhook_secret, state
),
existing_row as (
    select webhook_secret, state from gitlab_installations where id = $id
),
final_row as (
select * from attempted_insert

union

select * from existing_row
)
select * from final_row limit 1
