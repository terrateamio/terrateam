with ds as (
    select unnest($dirs::text[]) as path,
           unnest($workspaces::text[]) as workspace
)
select ds.path, ds.workspace
from ds
where not exists (
    select 1
    from work_manifest_dirspaceflows as wmdsf
    join github_work_manifests as gwm
        on gwm.id = wmdsf.work_manifest
    join work_manifest_results as wmr
        on wmr.work_manifest = gwm.id
        and wmr.path = wmdsf.path
        and wmr.workspace = wmdsf.workspace
    where wmdsf.path = ds.path
      and wmdsf.workspace = ds.workspace
      and gwm.repository = $repository_id
      and gwm.base_sha = $base_ref
      and gwm.sha = $branch_ref
      and gwm.run_type in ('plan', 'autoplan')
      and gwm.state = 'completed'
      and wmr.success = true
)
