alter table work_manifests
    add column success boolean not null default true,
    add column branch text;

with
-- Set any work manifests to failed based on results table
failed_results as (
  select distinct
    wmr.work_manifest
  from work_manifests as wm
  inner join work_manifest_results as wmr
    on wmr.work_manifest = wm.id
  where not wmr.success
),
-- Set any work manifests to failed based on output steps
failed_outputs as (
  select distinct
    wso.work_manifest
  from work_manifests as wm
  inner join workflow_step_outputs as wso
    on wso.work_manifest = wm.id
  where wm.state = 'completed'
        and not wso.success
        and not wso.ignore_errors
)
update work_manifests
  set success = false
from failed_results as fr, failed_outputs as fo
where fr.work_manifest = work_manifests.id or fo.work_manifest = work_manifests.id;

-- Recreate the github view with the success column
create or replace view github_work_manifests as
       select
         wm.base_sha as base_sha,
         wm.completed_at as completed_at,
         wm.created_at as created_at,
         wm.id as id,
         gprm.pull_number as pull_number,
         grm.repository_id as repository,
         wm.run_id as run_id,
         wm.run_type as run_type,
         wm.sha as sha,
         wm.state as state,
         wm.tag_query as tag_query,
         wm.username as username,
         wm.dirspaces as dirspaces,
         wm.run_kind as run_kind,
         wm.environment as environment,
         wm.runs_on,
         gir.installation_id as installation_id,
         gir.owner as repo_owner,
         gir.name as repo_name,
         wm.success as success,
         wm.branch as branch
       from work_manifests as wm
       inner join github_repositories_map as grm
             on wm.repo = grm.core_id
       inner join github_installation_repositories as gir
             on gir.id = grm.repository_id
       left join github_pull_requests_map as gprm
            on wm.pull_request = gprm.core_id;

-- Recreate the gitlab view with the success column
create or replace view gitlab_work_manifests as
       select
         wm.base_sha as base_sha,
         wm.completed_at as completed_at,
         wm.created_at as created_at,
         wm.id as id,
         gprm.pull_number as pull_number,
         grm.repository_id as repository,
         wm.run_id as run_id,
         wm.run_type as run_type,
         wm.sha as sha,
         wm.state as state,
         wm.tag_query as tag_query,
         wm.username as username,
         wm.dirspaces as dirspaces,
         wm.run_kind as run_kind,
         wm.environment as environment,
         wm.runs_on,
         gir.installation_id as installation_id,
         gir.owner as repo_owner,
         gir.name as repo_name,
         wm.success as success,
         wm.branch as branch
       from work_manifests as wm
       inner join gitlab_repositories_map as grm
             on wm.repo = grm.core_id
       inner join gitlab_installation_repositories as gir
             on gir.id = grm.repository_id
       left join gitlab_pull_requests_map as gprm
            on wm.pull_request = gprm.core_id;
