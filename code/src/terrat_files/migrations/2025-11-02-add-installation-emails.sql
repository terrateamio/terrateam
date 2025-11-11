alter table github_installations
    add column email text;

alter table gitlab_installations
    add column email text;
