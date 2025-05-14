with
installation_id as (
    select
        gwm.sha as sha,
        gir.installation_id as installation_id
    from work_manifests as gwm
    inner join github_installation_repositories as gir
        on gir.id = gwm.repository
    where gwm.id = $work_manifest
    limit 1
)
insert into code_indexes (sha, installation_id, index, installation)
select sha, installation_id.installation_id, $index, gim.core_id from installation_id
inner join github_installations_map as gim
      on gim.installation_id = installation_id.installation_id
on conflict (installation_id, sha) do update set index = excluded.index
