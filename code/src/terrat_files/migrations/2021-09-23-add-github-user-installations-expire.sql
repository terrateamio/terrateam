alter table github_user_installations
      add column if not exists expiration timestamp with time zone not null default now();

alter table github_user_installations
      alter column expiration drop default;
