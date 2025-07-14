-- tag::schema[] 
-- Creating a test schema so people can easily nuke
-- this after testing it out.
-- DROP SCHEMA test_schema CASCADE
CREATE SCHEMA IF NOT EXISTS test_schema;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- end::schema[] 

-- tag::tables[] 
-- Tables
CREATE TABLE IF NOT EXISTS test_schema.strategy(
    id BIGINT NOT NULL CONSTRAINT id_is_always_positive CHECK (id > 0),
    name TEXT NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS test_schema.element_type(
    id BIGINT NOT NULL CONSTRAINT id_is_always_positive CHECK (id > 0),
    name TEXT NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS test_schema.element_source(
    id BIGINT NOT NULL CONSTRAINT id_is_always_positive CHECK (id > 0),
    name TEXT NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS test_schema.element_status(
    id BIGINT NOT NULL CONSTRAINT id_is_always_positive CHECK (id > 0),
    name TEXT NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS test_schema.github_comment(
    -- The original id github gave us
    id BIGINT NOT NULL CONSTRAINT id_is_always_positive CHECK (id > 0),
    pull_request BIGINT NOT NULL,
    repo BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    --Comment this just to make testing easier
    --FOREIGN KEY (repo, pull_request) REFERENCES github_pull_requests (repository, pull_number),
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS test_schema.github_element(
    id BIGINT NOT NULL CONSTRAINT id_is_always_positive CHECK (id > 0),
    type_id BIGINT NOT NULL,
    status_id BIGINT NOT NULL,
    strategy_id BIGINT NOT NULL,
    source_id BIGINT NOT NULL,
    -- Comment this to make testing easier
    -- This will link with the work_manifest, It can be NULL
    --work_manifest_id UUID,
    comment_id BIGINT NOT NULL,
    rendered_length BIGINT NOT NULL CONSTRAINT length_is_always_positive CHECK (rendered_length > 0),
    -- For a given element, there can be no overwrites if the types differ, 
    -- i.e. if an element with ID = X was originally the output of a 'plan'
    -- operation, it cannot hold the output of a 'terrateam apply' and
    -- vice-versa. It can still be overwritten by an upsert with the same
    -- type, but that will depend on the selected strategy.
    EXCLUDE USING GIST (id WITH =, comment_id WITH =, type_id WITH <>),
    FOREIGN KEY (type_id) REFERENCES test_schema.element_type(id),
    FOREIGN KEY (status_id) REFERENCES test_schema.element_status(id),
    FOREIGN KEY (source_id) REFERENCES test_schema.element_source(id),
    FOREIGN KEY (strategy_id) REFERENCES test_schema.strategy(id),
    FOREIGN KEY (comment_id) REFERENCES test_schema.github_comment(id),
    PRIMARY KEY (id)
);

-- end::tables[] 

-- tag::indexes[] 
-- Indexes
-- Merelly an experiment, some of these worked fine and produced
-- index-only scans on EXPLAIN ANALYZE. Further test is still
-- to make sure they are workig as expected.
CREATE INDEX IF NOT EXISTS idx_element_status_with_name
ON test_schema.element_status USING BTREE(id)
INCLUDE(name);

CREATE INDEX IF NOT EXISTS idx_element_type_with_name
ON test_schema.element_type USING BTREE(id)
INCLUDE(name);

CREATE INDEX IF NOT EXISTS idx_element_source_with_name
ON test_schema.element_source USING BTREE(id)
INCLUDE(name);

CREATE INDEX IF NOT EXISTS idx_strategy_with_name
ON test_schema.strategy USING BTREE(id)
INCLUDE(name);

CREATE INDEX IF NOT EXISTS idx_github_element
ON test_schema.github_element USING BTREE(id)
INCLUDE(comment_id, strategy_id, type_id, source_id);

CREATE INDEX IF NOT EXISTS idx_github_pr_comments
ON test_schema.github_comment USING BTREE(repository, pr_number);

-- end::indexes[] 

-- tag::data[] 
-- Test Data
INSERT INTO test_schema.strategy(id, name)
VALUES (1, 'append'), (2, 'minimize'), (3, 'delete');

INSERT INTO test_schema.element_type(id, name)
VALUES (1, 'plan'), (2, 'apply'), (3, 'config_error'), (4, 'custom_setup_error');

INSERT INTO test_schema.element_source(id, name)
VALUES (1, 'work_manifest'), (2, 'apply_requirement'), (3, 'gatekeeper');

INSERT INTO test_schema.element_status(id, name)
VALUES (1, 'success'), (2, 'failure');

INSERT INTO test_schema.github_comment(id, pull_request, repo)
VALUES 
    (1000, 100, 1010),
    (1001, 100, 1010);

INSERT INTO test_schema.github_element(
    id, 
    type_id, 
    status_id, 
    strategy_id, 
    source_id, 
    comment_id, 
    rendered_length
)
VALUES 
    (1, 1, 2, 1, 1, 1000, 128),
    (2, 1, 1, 1, 1, 1000, 256),
    (3, 1, 1, 1, 2, 1001, 512);
-- end::data[] 

-- tag::queries[] 
-- Example Queries
-- This can be later used as a prepared statement
SELECT
    gc.id as comment_id,
    ge.id as element_id,
    et.name as element_type,
    es.name as element_status,
    s.name as strategy,
    ge.rendered_length
FROM test_schema.github_element ge
JOIN test_schema.github_comment gc ON gc.id = ge.comment_id
JOIN test_schema.strategy s ON s.id = ge.strategy_id
JOIN test_schema.element_status es ON es.id = ge.status_id
JOIN test_schema.element_type et ON et.id = ge.type_id
JOIN test_schema.element_source esrc ON esrc.id = ge.source_id;

-- end::queries[] 
