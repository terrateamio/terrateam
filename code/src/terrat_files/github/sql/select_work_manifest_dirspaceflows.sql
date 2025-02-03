select
    path,
    workflow_idx,
    workspace
from github_work_manifest_dirspaceflows
where work_manifest = $id
