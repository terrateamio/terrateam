-- tag::types[] 
-- Creating a test schema so people can easily nuke
-- this after testing it out.
-- DROP SCHEMA test_schema CASCADE
CREATE SCHEMA IF NOT EXISTS test_schema;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Custom Types
--CREATE TYPE test_schema.github_comment_class AS ENUM (
--    'singleton',
--    'part'
--);

CREATE TYPE test_schema.github_policy_update_strategy AS ENUM (
    'append',
    'delete',
    'minimize',
    'update'
);

-- end::types[] 

-- tag::tables[] 
-- Tables

CREATE TABLE IF NOT EXISTS test_schema.github_comment(
    -- The original id github gave us
    id BIGINT NOT NULL CONSTRAINT id_is_always_positive CHECK (id > 0),
    pull_request BIGINT NOT NULL,
    repo BIGINT NOT NULL,
    --run_type TEXT NOT NULL,
    -- This will link with the work_manifest (Optional)
    work_manifest_id UUID,
    -- If idx
    idx BIGINT NOT NULL CONSTRAINT idx_is_non_negative CHECK (idx >= 0),
    strategy test_schema.github_policy_update_strategy NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- For a given comment, there can be no overwrites if the run types
    -- differ, i.e. if a comment with ID = X was originally the output of a
    -- 'terrateam plan', it cannot hold the output of a 'terrateam apply',
    -- and vice-versa. It can still be overwritten by an upsert with the same
    -- type, but that will depend on the selected policy.
    -- EXCLUDE USING GIST (id WITH =, run_type WITH <>),
    -- Commented some FKs, just to make it easier to test (below)
    --FOREIGN KEY (repo, pull_request) REFERENCES github_pull_requests (repository, pull_number),
    FOREIGN KEY (work_manifest_id) REFERENCES work_manifests(id),
    PRIMARY KEY (id)
);

-- Unfortunately, GIST does not support ENUMs yet, so you need
-- to work around in this crappy way, using OIDs to make ENUM
-- comparisson behave in a IMMUTABLE way.
-- https://www.postgresql.org/message-id/CAMjNa7dGN-DZjbMn5sY52ACR_Np9Kx8F6Pf%3Dc5k0%2Bd1f_hZU%3Dg%40mail.gmail.com
CREATE TABLE IF NOT EXISTS test_schema.github_work_manifest_comment(
    -- The original id github gave us
    id BIGINT NOT NULL CONSTRAINT id_is_always_positive CHECK (id > 0),
    -- This will link with the work_manifest
    work_manifest_id UUID NOT NULL,
    pr_number BIGINT NOT NULL,
    repository BIGINT NOT NULL,
    run_type TEXT NOT NULL,
    policy BIGINT NOT NULL,
    class test_schema.github_comment_class,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    -- For a given comment, there can be no overwrites if the run types
    -- differ, i.e. if a comment with ID = X was originally the output of a
    -- 'terrateam plan', it cannot hold the output of a 'terrateam apply',
    -- and vice-versa. It can still be overwritten by an upsert with the same
    -- type, but that will depend on the selected policy.
    EXCLUDE USING GIST (id WITH =, run_type WITH <>),
    -- Commented some FKs, just to make it easier to test (below)
    -- FOREIGN KEY (pr_number) REFERENCES github_pull_requests (pull_number),
    -- FOREIGN KEY (repository) REFERENCES github_pull_requests (repository),
    FOREIGN KEY (work_manifest_id) REFERENCES work_manifests(id),
    PRIMARY KEY (id)
);

-- TODO: Improve this
CREATE TABLE IF NOT EXISTS test_schema.github_summary_comment(
    id BIGINT NOT NULL CONSTRAINT id_is_always_positive CHECK (id > 0),
    pr_number BIGINT NOT NULL,
    repository BIGINT NOT NULL,
    -- Commented some FKs, just to make it easier to test (below)
    -- FOREIGN KEY (pr_number) REFERENCES github_pull_requests (pull_number),
    -- FOREIGN KEY (repository) REFERENCES github_pull_requests (repository),
    PRIMARY KEY (id)
);

-- This is a proposal to help "traverse" big comments that got broken
-- into smaller chunks.
CREATE TABLE IF NOT EXISTS test_schema.github_work_manifest_comment_chain(
    id INTEGER REFERENCES test_schema.github_work_manifest_comment(id),
    next INTEGER REFERENCES test_schema.github_work_manifest_comment(id),
    PRIMARY KEY (id)
);

-- end::tables[] 

-- tag::views[] 
-- Views

-- end::views[] 

-- tag::functions[] 
-- Functions & Triggers

-- end::functions[] 

-- tag::indexes[] 
-- Indexes
CREATE INDEX idx_github_pr_comments
ON test_schema.github_comment USING BTREE(repository, pr_number)
INCLUDE(id, policy, comment_type);

CREATE INDEX idx_github_work_manifest_comment
ON test_schema.github_comment USING BTREE(work_manifest_id)
INCLUDE(id, policy, run_type);

-- end::indexes[] 

-- tag::data[] 
-- Test Data
INSERT INTO test_schema.github_comment_type(name)
VALUES ('plan'), ('apply'), ('summary');

INSERT INTO test_schema.github_notification_policy(id, strategy, enable_summary)
VALUES 
    (1, 'append', true),
    (2, 'minimize', true);

INSERT INTO test_schema.github_comment(id, pr_number, repository, policy, comment_type)
VALUES 
    (1, 1, 1, 1, 1),
    (2, 1, 1, 1, 1),
    (3, 1, 1, 1, 2);

INSERT INTO test_schema.github_comment_chain(id, next)
VALUES 
    (1, 2),
    (2, 2);

-- end::data[] 

-- tag::queries[] 
-- Example Queries

WITH RECURSIVE comment_chain AS (
  SELECT
    id
  , next
  FROM test_schema.github_comment_chain c
  -- Recursion base case
  WHERE id=1

  UNION ALL

  SELECT
    c.id
  , c.next
  FROM comment_chain cc
  JOIN test_schema.github_comment_chain c ON cc.next = c.id
  WHERE c.next <> cc.id
)
SELECT *
FROM comment_chain;

-- end::queries[] 
