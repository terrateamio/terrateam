insert into drift_unlocks (repository, repo)
select $repository, grm.core_id from github_repositories_map as grm
where grm.repository_id = $repository
