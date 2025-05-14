insert into gate_approvals (
    approver,
    token,
    repository,
    pull_number,
    sha,
    pull_request
)
select
        $approver,
        $token,
        $repository,
        $pull_number,
        $sha
        gprm.core_id
from github_pull_requests_map as gprm
where gprm.repository_id = $repository and gprm.pull_number = $pull_number
on conflict (repository, pull_number, sha, token, approver)
do nothing
