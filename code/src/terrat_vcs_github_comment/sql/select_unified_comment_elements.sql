-- Recompute the state of every dirspace of the pull request that the given
-- work manifest belongs to, at the pull request's current sha.  The counts are
-- extracted from the plan output summary line when present.
with pr as (
    select
        gpr.repository,
        gpr.pull_number,
        gpr.base_sha,
        gpr.sha,
        gpr.merged_sha,
        gpr.state,
        grm.core_id as repo_core_id
    from github_work_manifests as gwm
    inner join github_pull_requests as gpr
        on gpr.repository = gwm.repository and gpr.pull_number = gwm.pull_number
    inner join github_repositories_map as grm
        on grm.repository_id = gpr.repository
    where gwm.id = $work_manifest
),
-- In the case that the pull request being evaluated here is merged, work
-- manifests run against the sha of the most recently merged pull request, so
-- accept that sha as well.
latest_merged_pull_request as (
    select gpr.repository, gpr.merged_sha
    from github_pull_requests as gpr
    inner join pr on pr.repository = gpr.repository
    where gpr.state = 'merged'
    order by gpr.merged_at desc
    limit 1
),
current_dirspaces as (
    select distinct cd.path, cd.workspace
    from change_dirspaces as cd
    inner join pr
        on pr.repo_core_id = cd.repo and pr.base_sha = cd.base_sha
    left join latest_merged_pull_request as lmpr
        on lmpr.repository = pr.repository
    where pr.sha = cd.sha
          or pr.merged_sha = cd.sha
          or (pr.state = 'merged' and cd.sha = lmpr.merged_sha)
),
pr_work_manifests as (
    select gwm.id, gwm.run_type, gwm.state, gwm.created_at
    from github_work_manifests as gwm
    inner join pr
        on pr.repository = gwm.repository
           and pr.pull_number = gwm.pull_number
           and pr.base_sha = gwm.base_sha
    left join latest_merged_pull_request as lmpr
        on lmpr.repository = pr.repository
    left join github_pull_request_latest_unlocks as lu
        on lu.repository = gwm.repository and lu.pull_number = gwm.pull_number
    where (pr.sha = gwm.sha
           or pr.merged_sha = gwm.sha
           or (pr.state = 'merged' and gwm.sha = lmpr.merged_sha))
          and gwm.run_type in ('plan', 'autoplan', 'apply', 'autoapply', 'unsafe-apply')
          and (lu.unlocked_at is null or lu.unlocked_at < gwm.created_at)
),
latest_plans as (
    select path, workspace, success, work_manifest
    from (
        select
            wmr.path,
            wmr.workspace,
            wmr.success,
            wm.id as work_manifest,
            row_number() over (partition by wmr.path, wmr.workspace
                               order by wm.created_at desc) as rn
        from pr_work_manifests as wm
        inner join work_manifest_results as wmr
            on wmr.work_manifest = wm.id
        where wm.run_type in ('plan', 'autoplan')
    ) as t
    where rn = 1
),
latest_applies as (
    select path, workspace, success, work_manifest
    from (
        select
            wmr.path,
            wmr.workspace,
            wmr.success,
            wm.id as work_manifest,
            row_number() over (partition by wmr.path, wmr.workspace
                               order by wm.created_at desc) as rn
        from pr_work_manifests as wm
        inner join work_manifest_results as wmr
            on wmr.work_manifest = wm.id
        where wm.run_type in ('apply', 'autoapply', 'unsafe-apply')
    ) as t
    where rn = 1
),
active_dirspaces as (
    select distinct wmd.path, wmd.workspace
    from pr_work_manifests as wm
    inner join work_manifest_dirspaceflows as wmd
        on wmd.work_manifest = wm.id
    where wm.state in ('queued', 'running')
),
aborted_dirspaces as (
    select distinct wmd.path, wmd.workspace
    from pr_work_manifests as wm
    inner join work_manifest_dirspaceflows as wmd
        on wmd.work_manifest = wm.id
    where wm.state = 'aborted'
      and not exists (select 1
                      from work_manifest_results as wmr
                      where wmr.work_manifest = wm.id)
)
select
    cd.path,
    cd.workspace,
    lp.success as plan_success,
    -- The plans row is deleted once an apply fetches the plan, so fall back to
    -- the plan step output which is retained forever.
    coalesce(p.has_changes, (po.payload->>'has_changes')::boolean) as plan_has_changes,
    lp.work_manifest as plan_work_manifest,
    -- Exact resource-change counts, computed by the runner from
    -- `terraform show -json`.  No text parsing: when a runner or engine does
    -- not emit them the columns are null (rendered as "-") rather than guessed.
    (po.payload->'resource_summary'->>'created')::bigint as created,
    (po.payload->'resource_summary'->>'updated')::bigint as updated,
    (po.payload->'resource_summary'->>'deleted')::bigint as deleted,
    (po.payload->'resource_summary'->>'replaced')::bigint as replaced,
    -- Inline output details are only rendered for small pull requests; at
    -- scale the unified comment is a table with console links.
    case when (select count(*) from current_dirspaces) <= 20 then
        coalesce(po.payload->>'plan', po.payload->>'text')
    end as plan_output,
    la.success as apply_success,
    la.work_manifest as apply_work_manifest,
    (ad.path is not null) as active,
    (ab.path is not null) as aborted
from current_dirspaces as cd
left join latest_plans as lp
    on lp.path = cd.path and lp.workspace = cd.workspace
left join plans as p
    on p.work_manifest = lp.work_manifest and p.path = lp.path and p.workspace = lp.workspace
left join lateral (
    select wso.payload
    from workflow_step_outputs as wso
    where wso.work_manifest = lp.work_manifest
      and wso.scope->>'type' = 'dirspace'
      and wso.scope->>'dir' = lp.path
      and wso.scope->>'workspace' = lp.workspace
      and wso.step in ('tf/plan', 'pulumi/plan', 'custom/plan', 'fly/plan', 'stategraph/plan')
    order by wso.idx desc
    limit 1
) as po on true
left join latest_applies as la
    on la.path = cd.path and la.workspace = cd.workspace
left join active_dirspaces as ad
    on ad.path = cd.path and ad.workspace = cd.workspace
left join aborted_dirspaces as ab
    on ab.path = cd.path and ab.workspace = cd.workspace
order by cd.path, cd.workspace
