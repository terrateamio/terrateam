with
rt1 as (
    select * from gitlab_repo_trees where installation_id = $installation_id and sha = $sha
),
base_sha_prs as (
    select * from gitlab_pull_requests where sha = $base_sha or merged_sha = $base_sha
),
rt2 as (
    select * from gitlab_repo_trees as rt
    inner join base_sha_prs as bsp
          on rt.sha in (bsp.sha, bsp.merged_sha)
    where rt.installation_id = $installation_id
)
select
    rt1.path,
    (case
       when rt1.changed is not null then rt1.changed
       when rt1.id is not null and rt2.id is not null then rt1.id <> rt2.id
       when rt1.id is not null and rt2.id is null then true
       else null
    end)
from rt1
left join rt2
     on rt1.path = rt2.path
