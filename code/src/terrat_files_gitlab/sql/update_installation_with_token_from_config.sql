update gitlab_installations 
set 
    access_token = $access_token_from_terrat_config
where id = $installation_id;
