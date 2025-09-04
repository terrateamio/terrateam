update gitlab_installations
set state = 'installed'
where id = $installation_id
