insert into github_installation_repositories (
       id,
       installation_id,
       name,
       owner
) values (
       $id,
       $installation_id,
       $name,
       $owner
) on conflict (id) do update set (installation_id, name, owner) = (excluded.installation_id, excluded.name, excluded.owner)
