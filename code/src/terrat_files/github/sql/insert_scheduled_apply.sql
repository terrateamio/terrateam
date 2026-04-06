insert into scheduled_applies (repo, pull_number, tag_query, scheduled_at, created_by)
values (
    (select core_id from github_repositories_map where repository_id = $repo),
    $pull_number, $tag_query, $scheduled_at::timestamptz, $created_by
)
returning id
