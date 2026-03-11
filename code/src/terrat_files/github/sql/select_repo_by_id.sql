select id, owner, name
from github_installation_repositories
where id = $repo_id and installation_id = $installation_id
