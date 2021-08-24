alter table github_user_installations
      add column if not exists admin boolean not null default false;
