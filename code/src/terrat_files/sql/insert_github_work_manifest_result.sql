insert into github_work_manifest_results (
       path,
       success,
       work_manifest,
       workspace
) select * from unnest(
       $path,
       $success,
       $work_manifest,
       $workspace
) on conflict do nothing
