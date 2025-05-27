select
    index
from github_code_indexes
where sha = $sha and installation_id = $installation_id
