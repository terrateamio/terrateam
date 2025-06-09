insert into repo_trees (sha, path, changed, id, installation)
select
        x.sha,
        x.path,
        x.changed,
        x.id,
        gim.core_id
from unnest(
  $installation_ids,
  $shas,
  $paths,
  $changed,
  $id
) as x(installation_id, sha, path, changed, id)
inner join gitlab_installations_map as gim
      on gim.installation_id = x.installation_id
on conflict on constraint repo_trees_pkey
do update set (
   changed,
   id
) = (
  excluded.changed,
  excluded.id
)
