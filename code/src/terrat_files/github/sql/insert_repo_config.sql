insert into repo_configs (installation_id, sha, data)
values($installation_id, $sha, $data) on conflict (installation_id, sha)
do update set data = excluded.data
