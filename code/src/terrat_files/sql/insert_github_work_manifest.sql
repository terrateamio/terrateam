insert into github_work_manifests (
       base_sha,
       pull_number,
       repository,
       run_type,
       sha,
       tag_query
) values (
       $base_sha,
       $pull_number,
       $repository,
       $run_type,
       $sha,
       $tag_query
)
returning id, state, to_char(created_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')