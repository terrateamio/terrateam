insert into github_pull_request_summary_comments(comment_id, pull_number, repository)
values ($comment_id, $pull_number, $repository)
on conflict (pull_number, repository)
do update 
set comment_id = excluded.comment_id,
    created_at = current_timestamp
