-- Only insert an unlock if the pull request exists
insert into pull_request_unlocks (pull_request)
select core_id from gitlab_pull_requests_map
where repository_id = $repository and pull_number = $pull_number
