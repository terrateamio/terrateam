insert into repo_trees (installation_id, sha, path, changed)
select * from unnest(
  $installation_ids,
  $shas,
  $paths,
  $changed
)
