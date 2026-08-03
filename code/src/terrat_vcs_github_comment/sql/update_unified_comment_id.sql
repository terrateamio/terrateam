update github_unified_comments
set comment_id = $comment_id
where repository = $repository and pull_number = $pull_number
