with
work_manifest as (
     select repository, pull_number, created_at
     from github_work_manifests as gwm
     where gwm.id = $id
),
deletable_terraform_plans as (
    select work_manifest, path, workspace
    from github_terraform_plans as gtp
    inner join github_work_manifests as gwm
       on gwm.id = gtp.work_manifest
    inner join work_manifest as wm
       on gwm.repository = wm.repository and gwm.pull_number = wm.pull_number
    where gwm.created_at <= wm.created_at and gtp.path = $dir and gtp.workspace = $workspace
)
delete from github_terraform_plans as gtp
using deletable_terraform_plans as dtp
where gtp.work_manifest = dtp.work_manifest and gtp.path = dtp.path and gtp.workspace = dtp.workspace
