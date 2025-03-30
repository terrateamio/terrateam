insert into github_gates (
    gate,
    repository,
    pull_number,
    sha,
    dir,
    workspace,
    token
)
values (
    $gate,
    $repository,
    $pull_number,
    $sha,
    $dir,
    $workspace,
    $token
)
on conflict (repository, pull_number, sha, dir, workspace, token)
do update set (
   gate,
   created_at
) = (
  excluded.gate,
  now()
)
