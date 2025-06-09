insert into gitlab_pull_requests_map (repository_id, pull_number)
values ($repository, $pull_number)
on conflict (repository_id, pull_number) do nothing
