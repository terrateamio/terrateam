delete from repo_configs where (now() - created_at) > interval '1 day'
