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
        $sha,
        gprm.core_id
from github_pull_requests_map as gprm
where gprm.repository_id = $repository and gprm.pull_number = $pull_number
on conflict on constraint gate_approvals_fut_pkey
do nothing
