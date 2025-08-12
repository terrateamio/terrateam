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
do update set (owner, name) = (excluded.owner, excluded.name)
where (r.owner, r.name) <> (excluded.owner, excluded.name)
