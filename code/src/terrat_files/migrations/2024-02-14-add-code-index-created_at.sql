alter table github_code_index
      add column created_at timestamp with time zone default now();
