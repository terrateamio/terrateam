create table adhoc_unlocks (
       repo uuid not null,
       unlocked_at timestamp with time zone not null default now(),
       primary key (repo, unlocked_at)
);

create view github_adhoc_unlocks as
       select
        grm.repository_id as repository,
        au.unlocked_at as unlocked_at
       from adhoc_unlocks as au
       inner join github_repositories_map as grm
             on au.repo = grm.core_id;

create view gitlab_adhoc_unlocks as
       select
        grm.repository_id as repository,
        au.unlocked_at as unlocked_at
       from adhoc_unlocks as au
       inner join gitlab_repositories_map as grm
             on au.repo = grm.core_id;

create view github_adhoc_latest_unlocks as
    select
        repository,
        max(unlocked_at) as unlocked_at
    from github_adhoc_unlocks
    group by repository;

create view gitlab_adhoc_latest_unlocks as
    select
        repository,
        max(unlocked_at) as unlocked_at
    from gitlab_adhoc_unlocks
    group by repository;
