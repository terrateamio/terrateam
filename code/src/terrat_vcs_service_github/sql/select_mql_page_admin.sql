-- MQL query wrapper (GitHub installation scoped, admin variant).
--
-- SECURITY: this is the [Mql_admin] counterpart of select_mql_page.sql. Each
-- CTE below shadows a real table with a copy filtered to a single GitHub
-- installation ($installation_id). Unlike select_mql_page.sql it does NOT join
-- github_user_installations2 / filter on $user_id, so it returns data for ANY
-- installation regardless of the caller's membership. It is therefore reachable
-- ONLY from the MQL endpoint when the caller holds the Mql_admin capability;
-- tokens carrying that capability are minted out-of-band.
--
-- Every table in the MQL allow-list (`schema` in
-- terrat_vcs_service_github_ep_mql.ml) MUST have an installation-scoped CTE
-- here; otherwise that name resolves to the real, unscoped table -> data for
-- every installation. Keep the CTE names identical to select_mql_page.sql.
with
accessible_repos as (
  select
    gir.id as id,
    gir.installation_id as installation_id,
    gir.name as name,
    gir.owner as owner,
    gir.updated_at as updated_at,
    gir.setup as setup
  from github_installation_repositories as gir
  where gir.installation_id = $installation_id
),
repositories as (
  select
    id as id,
    installation_id as installation_id,
    name as name,
    owner as owner,
    updated_at as updated_at,
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
    pr.username as username,
    pr.created_at as created_at
  from github_pull_requests as pr
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
  from github_work_manifests as gwm
  where gwm.installation_id = $installation_id
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
  from github_gates as gg
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
  from github_gate_approvals as gga
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
  from github_drift_schedules as gds
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
  from github_change_dirspaces as gcd
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
  from github_repo_trees as grt
  where grt.installation_id = $installation_id
),
code_indexes as (
  select
    gci.sha as sha,
    gci.installation_id as installation_id,
    gci.index as index,
    gci.created_at as created_at
  from github_code_indexes as gci
  where gci.installation_id = $installation_id
),
q as (
{{q}}
)
select to_json(q) from q
