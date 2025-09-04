alter table github_user_emails
add column is_primary boolean not null default false;

-- Update existing records to set primary email based on github_users2 table
-- This assumes the email in github_users2 is the primary one
update github_user_emails
set is_primary = true
where (username, email) in (
    select username, email
    from github_users2
    where email is not null
);