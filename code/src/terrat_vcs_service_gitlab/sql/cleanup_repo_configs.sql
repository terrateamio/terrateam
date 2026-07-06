delete from repo_configs
where (kind = 'built' and (now() - created_at) > interval '1 day')
   or (kind = 'derived' and (now() - created_at) > interval '90 days')
