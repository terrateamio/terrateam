select stacks from pull_request_stacks as stacks
inner join gitlab_pull_requests_map as gprm
    on gprm.core_id = stacks.pull_request
where gprm.repository_id = $repo_id and gprm.pull_number = $pull_number
