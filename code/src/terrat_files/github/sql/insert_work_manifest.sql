insert into work_manifests (
       base_sha,
       run_type,
       sha,
       tag_query,
       username,
       dirspaces,
       run_kind,
       environment,
       runs_on,
       pull_request,
       repo
)
select
       $base_sha,
       $run_type,
       $sha,
       $tag_query,
       $username,
       $dirspaces,
       $run_kind,
       $environment,
       $runs_on,
       gprm.core_id,
       grm.core_id
from github_repositories_map as grm
left join github_pull_requests_map as gprm
     on gprm.repository_id = grm.repository_id
        and gprm.pull_number = $pull_number
where grm.repository_id = $repository
returning id, state, to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
