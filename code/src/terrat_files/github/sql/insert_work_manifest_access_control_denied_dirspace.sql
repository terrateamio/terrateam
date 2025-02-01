insert into github_work_manifest_access_control_denied_dirspaces (path, workspace, policy, work_manifest)
select
    path,
    workspace,
    array(select * from json_array_elements_text(policy)) as policy,
    work_manifest
from unnest($path, $workspace, $policy, $work_manifest) as t(path, workspace, policy, work_manifest)
