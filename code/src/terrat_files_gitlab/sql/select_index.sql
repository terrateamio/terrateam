select
    index
from gitlab_code_indexes
where sha = $sha and installation_id = $installation_id
