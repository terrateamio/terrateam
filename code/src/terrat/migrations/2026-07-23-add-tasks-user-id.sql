alter table tasks add column user_id uuid;

create index if not exists tasks_user_id_idx on tasks (user_id);
