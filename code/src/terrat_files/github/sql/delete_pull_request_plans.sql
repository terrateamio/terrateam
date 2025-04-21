with
deletable_plans as (
    select work_manifest, path, workspace
    from plans as gtp
    inner join work_manifests as gwm
        on gwm.id = gtp.work_manifest
    inner join github_installation_repositories as gir
        on gir.id = gwm.repository
    where gwm.repository = $repo_id and gwm.pull_number = $pull_number
)
delete from plans as gtp
using deletable_plans as dtp
where gtp.work_manifest = dtp.work_manifest and gtp.path = dtp.path and gtp.workspace = dtp.workspace
