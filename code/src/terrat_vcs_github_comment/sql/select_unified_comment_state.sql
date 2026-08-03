select
    gwm.repository,
    gwm.pull_number,
    gwm.installation_id,
    gwm.repo_owner,
    gwm.repo_name,
    guc.comment_id,
    guc.dirty
from github_work_manifests as gwm
inner join github_unified_comments as guc
    on guc.repository = gwm.repository and guc.pull_number = gwm.pull_number
where gwm.id = $work_manifest
