-- Only insert an unlock if the pull request exists
insert into pull_request_unlocks (repository, pull_number, pull_request)
select repository_id, pull_number, core_id from github_pull_requests_map
where repository_id = $repository and pull_number = $pull_number
