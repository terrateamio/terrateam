insert into gitlab_installation_repositories as r (
       id,
       installation_id,
       name,
       owner
) values (
       $id,
       $installation_id,
       $name,
       $owner
) on conflict (id)
do update set (installation_id, name, owner) = (excluded.installation_id, excluded.name, excluded.owner)
where (r.installation_id, r.name, r.owner) <> (excluded.installation_id, excluded.name, excluded.owner)
