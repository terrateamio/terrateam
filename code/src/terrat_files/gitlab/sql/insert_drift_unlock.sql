insert into drift_unlocks (repo)
select grm.core_id from github_repositories_map as grm
where grm.repository_id = $repository
