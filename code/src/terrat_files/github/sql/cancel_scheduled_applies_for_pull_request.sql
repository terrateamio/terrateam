update scheduled_applies
set state = 'cancelled'
where repo = (
    select core_id
    from github_repositories_map
    where repository_id = $repository
)
and pull_number = $pull_number
and state = 'pending'
returning id
