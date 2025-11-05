alter table work_manifests
    add column success boolean;

-- Set any work manifests to failed based on results table
update work_manifests
    set success = false
from work_manifest_results as wmr
where wmr.work_manifest = work_manifests.id
      and work_manifests.state = 'completed'
      and not wmr.success;

-- Set any work manifests to failed based on output steps
update work_manifests
    set success = false
from workflow_step_outputs as wso
where wso.work_manifest = work_manifests.id
      and work_manifests.state = 'completed'
      and not wso.success and not wso.ignore_errors;

-- Set any remaining ones to success
update work_manifests
    set success = true
where state = 'completed' and success is null;

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
         wm.success as success
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
         wm.success as success
       from work_manifests as wm
       inner join gitlab_repositories_map as grm
             on wm.repo = grm.core_id
       inner join gitlab_installation_repositories as gir
             on gir.id = grm.repository_id
       left join gitlab_pull_requests_map as gprm
            on wm.pull_request = gprm.core_id;
