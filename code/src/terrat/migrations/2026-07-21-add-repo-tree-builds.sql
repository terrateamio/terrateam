-- Records that a repo tree was successfully built for a commit.
--
-- The rows in [repo_trees] cannot distinguish "the tree was built and it is
-- empty" from "the tree was never built", because an empty tree stores zero
-- rows.  A tree builder that legitimately outputs no files was therefore
-- treated as a missing tree and failed the evaluation.  This table records the
-- build itself so the two cases can be told apart.
create table repo_tree_builds (
    sha text not null,
    installation uuid not null,
    created_at timestamp with time zone not null default (now()),
    primary key (installation, sha)
);

-- Backfill the trees we already have so existing commits are not rebuilt.
insert into repo_tree_builds (installation, sha)
select distinct installation, sha from repo_trees
on conflict do nothing;
