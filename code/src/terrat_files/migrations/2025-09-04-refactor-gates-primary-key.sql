-- We want to support empty tokens for gates so we will drop the primary key and
-- remove the constraint on token.
alter table gates
  drop constraint gates_pkey,
  alter column token drop not null,
  add column name text;

-- We'll then create a unique index on gates where we treat nulls as unique.
-- This gives us our index plus uniqueness when a token is set.
create unique index gates_token_idx on gates (pull_request, sha, dir, workspace, token) nulls distinct;

drop view github_gates;

create view github_gates as
       select
        g.created_at created_at,
        g.dir as dir,
        g.gate as gate,
        gprm.pull_number as pull_number,
        gprm.repository_id as repository,
        g.sha as sha,
        g.token as token,
        g.name as name,
        g.workspace as workspace
       from gates as g
       inner join github_pull_requests_map as gprm
             on g.pull_request = gprm.core_id;

drop view gitlab_gates;

create view gitlab_gates as
       select
        g.created_at created_at,
        g.dir as dir,
        g.gate as gate,
        gprm.pull_number as pull_number,
        gprm.repository_id as repository,
        g.sha as sha,
        g.token as token,
        g.name as name,
        g.workspace as workspace
       from gates as g
       inner join gitlab_pull_requests_map as gprm
             on g.pull_request = gprm.core_id;
