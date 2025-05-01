delete from drift_schedules
using github_repositories_map as grm
where grm.core_id = drift_schedules.repo
      and grm.repository_id = $repo_id
      and not (name = any($names))
