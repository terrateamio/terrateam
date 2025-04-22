insert into plans
       (work_manifest, path, workspace, data, has_changes)
values (
   $work_manifest,
   $path,
   $workspace,
   decode($data, 'base64'),
   $has_changes)
on conflict (work_manifest, path, workspace)
do update set (data, has_changes) = (excluded.data, excluded.has_changes)
