select 
    wm.id,
    gwmc.dir,
    gwmc.workspace,
    wm.run_type,
    wso.ignore_errors,
    wso.payload,
    wso.scope,
    wso.success,
    wso.step
from github_work_manifest_comments gwmc
inner join work_manifests wm on gwmc.work_manifest = wm.id
inner join workflow_step_outputs wso on (
        wso.work_manifest = wm.id 
    and wso.scope->>'type' = 'dirspace'
    and gwmc.dir = wso.scope->>'dir' 
    and gwmc.workspace = wso.scope->>'workspace'
)
where 
    gwmc.comment_id = $comment_id
ORDER BY wso.idx
