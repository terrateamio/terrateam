insert into repo_configs (installation_id, sha, data, installation)
select
        $installation_id,
        $sha,
        $data,
        gim.core_id
from github_installations_map as gim
where gim.installation_id = $installation_id
on conflict on constraint repo_configs_fut_pkey
do update set data = excluded.data
