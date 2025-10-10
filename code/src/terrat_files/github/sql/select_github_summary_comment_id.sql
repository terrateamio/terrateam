select
  s.comment_id
from github_pull_request_summary_comments s
where
    s.pull_number = $pull_number
and s.repository = $repository
for update of s
