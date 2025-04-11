select
    path,
    changed
from github_repo_trees
where sha = $sha and installation_id = $installation_id
