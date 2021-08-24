alter table github_users
      add column if not exists avatar_url varchar(1024);
