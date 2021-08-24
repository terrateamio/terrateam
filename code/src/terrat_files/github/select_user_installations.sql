select
        github_installations.login,
        github_user_installations.installation_id,
        github_user_installations.admin
from github_user_installations
inner join github_installations on github_installations.id = github_user_installations.installation_id
where github_user_installations.user_id = $user_id
      and now() < expiration
order by github_installations.login
