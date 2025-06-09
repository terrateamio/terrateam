insert into gate_approvals (
    approver,
    token,
    sha,
    pull_request
)
select
        $approver,
        $token,
        $sha,
        gprm.core_id
from gitlab_pull_requests_map as gprm
where gprm.repository_id = $repository and gprm.pull_number = $pull_number
on conflict on constraint gate_approvals_pkey
do nothing
