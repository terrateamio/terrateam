alter table github_work_manifests add column dirspaces jsonb;


create index github_work_manifests_dirspace_idx
       on github_work_manifests
       using GIN (dirspaces jsonb_path_ops);

update
        github_work_manifests as gwm
set
        dirspaces = to_jsonb((select jsonb_agg(jsonb_build_object(
                                  'dir', gwmds.path,
                                  'workspace', gwmds.workspace))
              from github_work_manifest_dirspaceflows as gwmds
              left join github_work_manifest_results as gwmr
                  on gwmds.work_manifest = gwmr.work_manifest
                  and gwmds.path = gwmr.path
                  and gwmds.workspace = gwmr.workspace
               where gwmds.work_manifest = gwm.id))
where dirspaces is null;
