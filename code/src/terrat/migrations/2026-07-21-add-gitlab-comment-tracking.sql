-- Mirrors github_work_manifest_comments (2025-08-20-add-comment-tracking.sql).
-- Without it the GitLab comment layer cannot map a dirspace back to the note it
-- previously posted, so the minimize and delete comment strategies have nothing
-- to act on and every run can only append.
--
-- comment_id is a bigint because Terrat_vcs_api_gitlab.Comment.Id.t is an int
-- holding a GitLab note id.
--
-- Backwards compatible: a new table with no changes to existing relations, so
-- an older server ignores it entirely.
create table if not exists gitlab_work_manifest_comments(
    -- the original id gitlab gave us
    comment_id bigint not null,
    work_manifest uuid not null,
    dir text not null,
    workspace text not null,
    pull_number bigint not null,
    repository bigint not null,
    unified_run_type text not null,
    created_at timestamptz default current_timestamp,
    foreign key (work_manifest, dir, workspace)
        references work_manifest_results (work_manifest, path, workspace),
    foreign key (repository, pull_number)
        references gitlab_pull_requests (repository, pull_number),
    primary key (repository, pull_number, dir, workspace, unified_run_type)
);

create index if not exists gitlab_work_manifest_comment_idx
    on gitlab_work_manifest_comments(comment_id);
