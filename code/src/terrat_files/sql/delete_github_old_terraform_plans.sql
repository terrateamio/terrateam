delete from github_terraform_plans as gtp
using github_work_manifests as gwm
where gtp.work_manifest = gwm.id and gwm.created_at < now() - interval '14 days'
