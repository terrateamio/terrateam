with
work_manifests as (
    select
        id,
        created_at,
        repository,
        state,
        (case run_type
         when 'autoapply' then 'apply'
         when 'apply' then 'apply'
         when 'autoplan' then 'plan'
         when 'plan' then 'plan'
         end) as unified_run_type,
        (case run_type
         when 'autoapply' then 0
         when 'apply' then 0
         when 'autoplan' then 1
         when 'plan' then 1
         end) as priority
    from github_work_manifests
),
-- Find all repositories with a currently running apply.  The count should only
-- ever be 0 or 1
running_applies as (
    select repository from work_manifests
    where unified_run_type = 'apply' and state = 'running'
    group by repository
    having count(*) > 0
),
running_plans as (
    select repository from work_manifests
    where unified_run_type = 'plan' and state = 'running'
    group by repository
    having count(*) > 0
),
next_work_manifests as (
    select
        id,
        row_number() over (partition by wm.repository order by wm.priority, wm.created_at) as rn
    from work_manifests as wm
    left join running_applies as ra on ra.repository = wm.repository
    left join running_plans as rp on rp.repository = wm.repository
    where
-- (1) is an apply and nothing is running
        (wm.state = 'queued'
         and wm.unified_run_type = 'apply'
         and ra.repository is null
         and rp.repository is null)
-- (2) a plan and no applies running
        or (wm.state = 'queued'
            and wm.unified_run_type = 'plan'
            and ra.repository is null)
)
update github_work_manifests set state = 'running' where id = (
    select gwm.id from github_work_manifests as gwm
    inner join next_work_manifests as nwm on nwm.id = gwm.id
    where nwm.rn = 1
    for update skip locked
    limit 1)
returning id
