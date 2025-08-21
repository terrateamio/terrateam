insert into github_repositories_map (repository_id)
select id from github_installation_repositories
on conflict (repository_id) do nothing;

insert into github_installations_map (installation_id)
select id from github_installations
on conflict (installation_id) do nothing;

insert into github_pull_requests_map (repository_id, pull_number)
select repository, pull_number from github_pull_requests
on conflict (repository_id, pull_number) do nothing;
