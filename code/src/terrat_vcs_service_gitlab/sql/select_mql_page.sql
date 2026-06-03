-- MQL query wrapper (GitLab installation scoped).
--
-- SECURITY: each CTE below shadows a real table with a copy filtered to a
-- single GitLab installation that the calling user is a member of (the user
-- MQL query is substituted into the `q` CTE, where every table name resolves
-- to one of these scoped CTEs). Every table in the MQL allow-list (`schema` in
-- terrat_vcs_service_gitlab_ep_mql.ml) MUST have an installation-scoped CTE
-- here; otherwise that name resolves to the real, unscoped table -> cross
-- installation data exposure. Keep the allow-list a subset of the CTE names
-- defined here.
--
-- Scoping is defense-in-depth: even though the endpoint already calls
-- enforce_installation_access before running this query, every CTE both
-- filters on $installation_id and joins gitlab_user_installations2 on
-- $user_id.
with
accessible_repos as (
  select
    gir.id as id,
    gir.installation_id as installation_id,
    gir.name as name,
    gir.owner as owner,
    gir.updated_at as updated_at,
    gir.created_at as created_at,
    gir.setup as setup
  from gitlab_installation_repositories as gir
  inner join gitlab_user_installations2 as gui
    on gui.installation_id = gir.installation_id
  where gui.user_id = $user_id
    and gir.installation_id = $installation_id
),
repositories as (
  select
    id as id,
    installation_id as installation_id,
    name as name,
    owner as owner,
    updated_at as updated_at,
    created_at as created_at,
    setup as setup
  from accessible_repos
),
pull_requests as (
  select
    pr.base_branch as base_branch,
    pr.base_sha as base_sha,
    pr.branch as branch,
    pr.pull_number as pull_number,
    pr.repository as repository,
    pr.sha as sha,
    pr.state as state,
    pr.merged_sha as merged_sha,
    pr.merged_at as merged_at,
    pr.title as title,
    pr.username as username
  from gitlab_pull_requests as pr
  inner join accessible_repos as ar
    on ar.id = pr.repository
),
work_manifests as (
  select
    gwm.id as id,
    gwm.base_sha as base_sha,
    gwm.completed_at as completed_at,
    gwm.created_at as created_at,
    gwm.pull_number as pull_number,
    gwm.repository as repository,
    gwm.run_id as run_id,
    gwm.run_type as run_type,
    gwm.sha as sha,
    gwm.state as state,
    gwm.tag_query as tag_query,
    gwm.username as username,
    gwm.dirspaces as dirspaces,
    gwm.run_kind as run_kind,
    gwm.environment as environment,
    gwm.runs_on as runs_on,
    gwm.installation_id as installation_id,
    gwm.repo_owner as repo_owner,
    gwm.repo_name as repo_name,
    gwm.branch as branch
  from gitlab_work_manifests as gwm
  inner join gitlab_user_installations2 as gui
    on gui.installation_id = gwm.installation_id
  where gui.user_id = $user_id
    and gwm.installation_id = $installation_id
),
gates as (
  select
    gg.created_at as created_at,
    gg.dir as dir,
    gg.gate as gate,
    gg.pull_number as pull_number,
    gg.repository as repository,
    gg.sha as sha,
    gg.name as name,
    gg.workspace as workspace
  from gitlab_gates as gg
  inner join accessible_repos as ar
    on ar.id = gg.repository
),
gate_approvals as (
  select
    gga.approver as approver,
    gga.created_at as created_at,
    gga.pull_number as pull_number,
    gga.repository as repository,
    gga.sha as sha
  from gitlab_gate_approvals as gga
  inner join accessible_repos as ar
    on ar.id = gga.repository
),
drift_schedules as (
  select
    gds.reconcile as reconcile,
    gds.repository as repository,
    gds.schedule as schedule,
    gds.updated_at as updated_at,
    gds.tag_query as tag_query,
    gds.name as name,
    gds.branch as branch,
    gds.last_tried_at as last_tried_at
  from gitlab_drift_schedules as gds
  inner join accessible_repos as ar
    on ar.id = gds.repository
),
change_dirspaces as (
  select
    gcd.base_sha as base_sha,
    gcd.path as path,
    gcd.repository as repository,
    gcd.sha as sha,
    gcd.workspace as workspace,
    gcd.lock_policy as lock_policy,
    gcd.branch_target as branch_target
  from gitlab_change_dirspaces as gcd
  inner join accessible_repos as ar
    on ar.id = gcd.repository
),
repo_trees as (
  select
    grt.installation_id as installation_id,
    grt.sha as sha,
    grt.created_at as created_at,
    grt.path as path,
    grt.changed as changed,
    grt.id as id
  from gitlab_repo_trees as grt
  inner join gitlab_user_installations2 as gui
    on gui.installation_id = grt.installation_id
  where gui.user_id = $user_id
    and grt.installation_id = $installation_id
),
code_indexes as (
  select
    gci.sha as sha,
    gci.installation_id as installation_id,
    gci.index as index,
    gci.created_at as created_at
  from gitlab_code_indexes as gci
  inner join gitlab_user_installations2 as gui
    on gui.installation_id = gci.installation_id
  where gui.user_id = $user_id
    and gci.installation_id = $installation_id
),
q as (
{{q}}
)
select to_json(q) from q
