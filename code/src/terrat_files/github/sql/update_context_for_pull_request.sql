update job_contexts as jc
set
    repo = grm.core_id,
    pull_request = gprm.core_id,
    updated_at = now()
from github_repositories_map as grm
inner join github_pull_requests_map as gprm
    on gprm.repository_id = grm.repository_id
where jc.id = $context_id and gprm.repository_id = $repo_id and gprm.pull_number = $pull_number
