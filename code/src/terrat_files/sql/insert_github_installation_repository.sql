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
) on conflict do nothing
