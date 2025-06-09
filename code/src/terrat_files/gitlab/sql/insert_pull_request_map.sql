insert into github_pull_requests_map (repository_id, pull_number)
values ($repository, $pull_number)
on conflict (repository_id, pull_number) do nothing
