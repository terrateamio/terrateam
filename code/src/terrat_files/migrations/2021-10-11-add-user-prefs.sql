alter table github_users
      add column if not exists receive_marketing_emails boolean not null default true,
      add column if not exists email varchar(256);
