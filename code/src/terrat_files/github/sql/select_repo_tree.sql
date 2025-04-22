select
    path,
    changed
from repo_trees
where sha = $sha and installation_id = $installation_id
