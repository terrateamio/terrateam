select
        gwm.installation_id
from github_work_manifests as gwm
where gwm.id = $id
