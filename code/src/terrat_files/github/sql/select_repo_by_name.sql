select id, owner, name
from github_installation_repositories
where installation_id = $installation_id and name = $name
