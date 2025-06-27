update gitlab_installations
set state = 'active'
where id = $installation_id
