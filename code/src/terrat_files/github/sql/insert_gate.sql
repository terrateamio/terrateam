insert into gates (
    gate,
    sha,
    dir,
    workspace,
    token,
    pull_request
)
select
        $gate,
        $sha,
        $dir,
        $workspace,
        $token,
        gprm.core_id
from github_pull_requests_map as gprm
where gprm.repository_id = $repository and gprm.pull_number = $pull_number
on conflict do nothing
