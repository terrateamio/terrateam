insert into gitlab_pull_requests (
    base_branch,
    base_sha,
    branch,
    pull_number,
    repository,
    sha,
    merged_sha,
    merged_at,
    state,
    title,
    username
)  values (
    $base_branch,
    $base_sha,
    $branch,
    $pull_number,
    $repository,
    $sha,
    $merged_sha,
    $merged_at,
    $state,
    $title,
    $username
) on conflict (repository, pull_number) do update set (
    base_branch,
    branch,
    base_sha,
    sha,
    merged_sha,
    merged_at,
    state,
    title,
    username
) = (
    excluded.base_branch,
    excluded.branch,
    excluded.base_sha,
    excluded.sha,
    excluded.merged_sha,
    excluded.merged_at,
    excluded.state,
    excluded.title,
    excluded.username
)
