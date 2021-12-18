insert into github_work_manifest_results (
       path,
       success,
       work_manifest,
       workspace
) values (
       $path,
       $success,
       $work_manifest,
       $workspace
) on conflict do nothing
