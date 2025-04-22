select
    index
from code_indexes
where sha = $sha and installation_id = $installation_id
