select
    index
from github_code_index
where sha = $sha and installation_id = $installation_id
