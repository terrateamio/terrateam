insert into work_manifest_dirspaceflows (
    work_manifest,
    path,
    workspace,
    workflow_idx
) select * from unnest($work_manifest, $path, $workspace, $workflow_idx)
on conflict (path, workspace, work_manifest) do nothing
