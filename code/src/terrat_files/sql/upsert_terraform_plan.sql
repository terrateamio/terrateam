insert into github_terraform_plans
       (work_manifest, path, workspace, data)
values (
   $work_manifest,
   $path,
   $workspace,
   decode($data, 'base64'))
on conflict (work_manifest, path, workspace)
do update set data = excluded.data
