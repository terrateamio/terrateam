insert into code_indexes (sha, index, installation)
select
        sha,
        $index,
        gim.core_id
from work_manifests as wm
inner join github_repositories_map as grm
      on grm.core_id = wm.repo
inner join github_installation_repositories as gir
      on gir.id = grm.repository_id
inner join github_installations_map as gim
      on gim.installation_id = gir.installation_id
where wm.id = $work_manifest
on conflict on constraint code_indexes_pkey do update set index = excluded.index
