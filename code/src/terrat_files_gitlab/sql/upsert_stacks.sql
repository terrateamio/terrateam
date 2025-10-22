with
pr as (
    select core_id from gitlab_pull_requests_map as gprm
    where gprm.repository_id = $repo_id and gprm.pull_number = $pull_number
)
insert into pull_request_stacks
    (pull_request, stacks)
select pr.core_id, $stacks from pr
on conflict (pull_request) do update set stacks = excluded.stacks
