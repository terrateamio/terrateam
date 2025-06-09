with
wm as (
     select repository, pull_number, created_at
     from github_work_manifests as gwm
     where gwm.id = $id
),
deletable_plans as (
    select work_manifest, path, workspace
    from plans as gtp
    inner join github_work_manifests as gwm
       on gwm.id = gtp.work_manifest
    inner join wm
       on gwm.repository = wm.repository and gwm.pull_number = wm.pull_number
    where gwm.created_at <= wm.created_at and gtp.path = $dir and gtp.workspace = $workspace
)
delete from plans as gtp
using deletable_plans as dtp
where gtp.work_manifest = dtp.work_manifest and gtp.path = dtp.path and gtp.workspace = dtp.workspace
