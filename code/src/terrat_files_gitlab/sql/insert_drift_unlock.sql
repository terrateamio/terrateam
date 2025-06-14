insert into drift_unlocks (repo)
select grm.core_id from gitlab_repositories_map as grm
where grm.repository_id = $repository
