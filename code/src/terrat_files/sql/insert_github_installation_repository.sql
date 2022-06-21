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
) on conflict (owner, name) do update set installation_id = excluded.installation_id
