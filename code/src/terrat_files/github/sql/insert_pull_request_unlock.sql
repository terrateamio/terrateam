-- Only insert an unlock if the pull request exists
insert into github_pull_request_unlocks (repository, pull_number)
select repository, pull_number from github_pull_requests
where repository = $repository and pull_number = $pull_number
