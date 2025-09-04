alter table gitlab_installation_repositories
    add column setup boolean default (true);
