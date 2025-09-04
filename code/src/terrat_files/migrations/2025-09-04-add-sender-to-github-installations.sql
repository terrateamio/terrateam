-- Add sender column to track who performed installation actions
alter table github_installations
add column sender text;