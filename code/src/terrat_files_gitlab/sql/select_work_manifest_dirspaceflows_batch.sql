select
    work_manifest,
    path,
    workflow_idx,
    workspace
from work_manifest_dirspaceflows
where work_manifest = ANY($ids)
