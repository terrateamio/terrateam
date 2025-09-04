-- We want to support empty tokens for gates so we will drop the primary key and
-- remove the constraint on token.
alter table gates
  drop constraint gates_pkey,
  alter column token drop not null;

-- We'll then create a unique index on gates where we treat nulls as unique.
-- This gives us our index plus uniqueness when a token is set.
create unique index gates_token_idx on gates (pull_request, sha, dir, workspace, token) nulls distinct;
