insert into repo_configs (sha, data, installation)
select
        $sha,
        $data,
        gim.core_id
from gitlab_installations_map as gim
where gim.installation_id = $installation_id
on conflict (installation, sha) where kind = 'built'
do update set data = excluded.data
