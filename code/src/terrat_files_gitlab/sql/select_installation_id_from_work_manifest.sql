select
        gwm.installation_id
from gitlab_work_manifests as gwm
where gwm.id = $id
