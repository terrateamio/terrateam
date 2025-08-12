insert into gitlab_installation_repositories (
  id,
  installation_id,
  owner,
  name,
  setup
)
select * from unnest($id, $installation_id, $owner, $name, $setup)
on conflict (id) do
update set (
  installation_id,
  owner,
  name,
  setup
) = (
  excluded.installation_id,
  excluded.owner,
  excluded.name,
  excluded.setup
)
