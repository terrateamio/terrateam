with
deletable_terraform_plans as (
    select work_manifest, path, workspace
    from github_terraform_plans as gtp
    inner join github_work_manifests as gwm
        on gwm.id = gtp.work_manifest
    inner join github_installation_repositories as gir
        on gir.id = gwm.repository
    where gir.owner = $owner and gir.name = $repo and gwm.pull_number = $pull_number
)
delete from github_terraform_plans as gtp
using deletable_terraform_plans as dtp
where gtp.work_manifest = dtp.work_manifest and gtp.path = dtp.path and gtp.workspace = dtp.workspace