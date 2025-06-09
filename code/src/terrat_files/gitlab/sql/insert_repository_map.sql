insert into github_repositories_map (repository_id)
values ($repository)
on conflict (repository_id) do nothing
