select
        name,
        value,
        modified_by,
        to_char(modified_time, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
from installation_env_vars
inner join github_user_installations on
      installation_env_vars.installation_id = github_user_installations.installation_id
where
        github_user_installations.user_id = $user_id and
        installation_env_vars.installation_id = $installation_id and
        not installation_env_vars.secret and
        now() < github_user_installations.expiration
