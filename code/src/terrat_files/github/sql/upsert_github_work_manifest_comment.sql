insert into github_work_manifest_comments(comment_id, work_manifest, dir, workspace)
values($comment_id, $work_manifest, $dir, $workspace)
on conflict (work_manifest, dir, workspace)
do update set (dir, workspace) = (excluded.dir, excluded.workspace)
