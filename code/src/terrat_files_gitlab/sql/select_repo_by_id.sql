select id, owner, name
from gitlab_installation_repositories
where id = $repo_id and installation_id = $installation_id
