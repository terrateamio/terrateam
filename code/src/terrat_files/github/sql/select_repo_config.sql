select
    repo_configs.data
from repo_configs
where sha = $sha and installation_id = $installation_id
