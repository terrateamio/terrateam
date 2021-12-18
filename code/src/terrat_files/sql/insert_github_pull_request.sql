insert into github_pull_requests (
    base_branch,
    base_sha,
    branch,
    pull_number,
    repository,
    sha,
    merged_sha,
    merged_at,
    state
)  values (
    $base_branch,
    $base_sha,
    $branch,
    $pull_number,
    $repository,
    $sha,
    $merged_sha,
    $merged_at,
    $state
) on conflict (repository, pull_number) do update set (
    base_branch,
    branch,
    base_sha,
    sha,
    merged_sha,
    merged_at,
    state
) = (
    excluded.base_branch,
    excluded.branch,
    excluded.base_sha,
    excluded.sha,
    excluded.merged_sha,
    excluded.merged_at,
    excluded.state
)
