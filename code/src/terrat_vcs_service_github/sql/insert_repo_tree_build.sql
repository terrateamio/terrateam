insert into repo_tree_builds (sha, installation)
select
        $sha,
        gim.core_id
from github_installations_map as gim
where gim.installation_id = $installation_id
on conflict on constraint repo_tree_builds_pkey
do nothing
