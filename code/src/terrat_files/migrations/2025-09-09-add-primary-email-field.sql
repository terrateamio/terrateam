alter table github_user_emails
    add column is_primary boolean not null default false;

alter table github_installations
    add column last_suspended_by text,
    add column last_suspended_at timestamp with time zone,
    add column last_unsuspended_by text,
    add column last_unsuspended_at timestamp with time zone,
    add column installed_by text,
    add column uninstalled_by text,
    add column uninstalled_at timestamp with time zone;
