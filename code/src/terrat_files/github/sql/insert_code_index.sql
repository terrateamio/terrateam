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
insert into code_indexes (sha, installation_id, index)
select sha, installation_id, $index from installation_id
on conflict (installation_id, sha) do update set index = excluded.index
