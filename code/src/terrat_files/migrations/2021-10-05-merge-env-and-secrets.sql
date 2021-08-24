set transaction isolation level repeatable read;

alter table installation_secrets rename to installation_env_vars;

alter table installation_env_vars add column if not exists secret boolean default true;

alter table installation_env_vars alter secret drop default;
