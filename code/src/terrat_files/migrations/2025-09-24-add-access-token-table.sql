create table access_tokens (
  capabilities jsonb,
  created_at timestamp with time zone not null default (now()),
  id uuid default gen_random_uuid() primary key,
  name text not null,
  user_id uuid not null,
  foreign key (user_id) references users2(id)
);
