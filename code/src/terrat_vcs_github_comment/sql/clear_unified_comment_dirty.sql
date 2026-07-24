update github_unified_comments
set dirty = 0
where repository = $repository and pull_number = $pull_number and dirty = $dirty
returning repository
