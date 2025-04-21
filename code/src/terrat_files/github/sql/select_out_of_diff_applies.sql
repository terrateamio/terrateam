select distinct
    gwmds.path,
    gwmds.workspace
from work_manifest_dirspaceflows as gwmds
inner join work_manifests as gwm on gwm.id = gwmds.work_manifest
inner join github_pull_requests as gpr
    on gpr.repository = gwm.repository and gpr.pull_number = gwm.pull_number
where gpr.repository = $repository and gpr.pull_number = $pull_number
      and (gpr.base_sha <> gwm.base_sha
           or (gpr.sha <> gwm.sha and (gpr.state <> 'merged' or gpr.merged_sha <> gwm.sha)))
      and gwm.run_type in ('apply', 'autoapply', 'unsafe-apply')
