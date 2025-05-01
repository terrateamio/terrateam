insert into gates (
    gate,
    repository,
    pull_number,
    sha,
    dir,
    workspace,
    token,
    pull_request
)
select
        $gate,
        $repository,
        $pull_number,
        $sha,
        $dir,
        $workspace,
        $token,
        gprm.core_id
from github_pull_requests_map as gprm
where gprm.repository_id = $repository and gprm.pull_number = $pull_number
on conflict on constraint gates_fut_pkey
do update set (
   gate,
   created_at
) = (
  excluded.gate,
  now()
)
