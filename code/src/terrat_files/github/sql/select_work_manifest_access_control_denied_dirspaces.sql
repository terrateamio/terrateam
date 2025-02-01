select path, workspace, to_json(policy)
from github_work_manifest_access_control_denied_dirspaces
where work_manifest = $work_manifest
