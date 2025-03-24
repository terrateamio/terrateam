select
    github_repo_configs.data
from github_repo_configs
where sha = $sha and installation_id = $installation_id
