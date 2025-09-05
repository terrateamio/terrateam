insert into gates (
    gate,
    sha,
    dir,
    workspace,
    token,
    name,
    pull_request
)
select
        $gate,
        $sha,
        $dir,
        $workspace,
        $token,
        $name,
        gprm.core_id
from github_pull_requests_map as gprm
where gprm.repository_id = $repository and gprm.pull_number = $pull_number
on conflict do nothing
