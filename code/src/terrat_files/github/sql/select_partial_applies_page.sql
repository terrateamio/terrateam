select
    gpr.base_branch as base_branch,
    gpr.base_sha as base_sha,
    gpr.branch as branch,
    gir.name as name,
    gir.owner as owner,
    gpr.pull_number as pull_number,
    gpr.repository as repository,
    gpr.sha as sha,
    gpr.state as state,
    gpr.title as title,
    gpr.username as username
from github_pull_requests as gpr
inner join github_installation_repositories as gir
    on gpr.repository = gir.id
inner join github_user_installations2 as gui
    on gir.installation_id = gui.installation_id
where gir.installation_id = $installation_id
      and gui.user_id = $user
      and gpr.all_dirspaces_applied = false
      and exists (
          select 1
          from github_work_manifests as gwm
          inner join work_manifest_results as wmr
              on wmr.work_manifest = gwm.id
          where gwm.repository = gpr.repository
                and gwm.pull_number = gpr.pull_number
                and gwm.base_sha = gpr.base_sha
                and (gwm.sha = gpr.sha or gwm.sha = gpr.merged_sha)
                and gwm.run_type in ('apply', 'autoapply', 'unsafe-apply')
                and wmr.success
      )
