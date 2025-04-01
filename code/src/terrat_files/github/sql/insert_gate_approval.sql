insert into github_gate_approvals (
    approver,
    token,
    repository,
    pull_number,
    sha
)
values (
    $approver,
    $token,
    $repository,
    $pull_number,
    $sha
)
on conflict (repository, pull_number, sha, token, approver)
do nothing
