insert into work_manifests (
       base_sha,
       pull_number,
       repository,
       run_type,
       sha,
       tag_query,
       username,
       dirspaces,
       run_kind,
       environment,
       runs_on
) values (
       $base_sha,
       $pull_number,
       $repository,
       $run_type,
       $sha,
       $tag_query,
       $username,
       $dirspaces,
       $run_kind,
       $environment,
       $runs_on
)
returning id, state, to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
