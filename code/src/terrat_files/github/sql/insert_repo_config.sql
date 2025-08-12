insert into repo_configs (sha, data, installation)
select
        $sha,
        $data,
        gim.core_id
from github_installations_map as gim
where gim.installation_id = $installation_id
on conflict on constraint repo_configs_pkey
do update set data = excluded.data
