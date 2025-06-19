create table if not exists gitlab_installation_states (
    id text primary key
);


insert into gitlab_installation_states (id) values ('pending'), ('active');


-- Installations in GitLab correspond to groups
create table if not exists gitlab_installations (
    account_status text not null default ('active'),
    created_at timestamp with time zone not null default (now()),
    id bigint not null,
    name text not null,
    state text not null default ('pending'),
    tier text not null default ('unlimited'),
    trial_ends_at timestamp with time zone,
    webhook_secret text not null default (encode(gen_random_bytes(32), 'hex')),
    primary key (id),
    foreign key (tier) references tiers (id)
);

create unique index gitlab_installations_webhook_secrets_idx
    on gitlab_installations (webhook_secret)
    include (id, state);

-- Installation repositories correspond to projects
create table if not exists gitlab_installation_repositories (
    created_at timestamp with time zone not null default (now()),
    id bigint primary key,
    installation_id bigint not null,
    name text not null,
    owner text not null,
    updated_at timestamp with time zone not null default (now())
);

create table if not exists gitlab_user_installations2 (
       user_id uuid not null,
       installation_id bigint not null,
       primary key (user_id, installation_id),
       foreign key (user_id) references users2 (id),
       foreign key (installation_id) references gitlab_installations (id)
);

create table if not exists gitlab_pull_request_states (
       id text primary key
);

insert into gitlab_pull_request_states values
    ('open'),
    ('closed'),
    ('merged');

create table gitlab_pull_requests (
       base_branch text NOT NULL,
       base_sha text NOT NULL,
       branch text NOT NULL,
       merged_at timestamp with time zone,
       merged_sha text,
       pull_number bigint NOT NULL,
       repository bigint NOT NULL,
       sha text NOT NULL,
       state text NOT NULL,
       title text,
       username text,
       primary key (repository, pull_number),
       foreign key (repository) references gitlab_installation_repositories (id),
       foreign key (state) references gitlab_pull_request_states (id),
       constraint gitlab_pull_requests_check check ((((state = 'merged') and (merged_sha is not null) and (merged_at is not null)) or (state <> 'merged')))
);

create table gitlab_repositories_map (
       repository_id bigint primary key,
       core_id uuid not null default (gen_random_uuid()),
       foreign key (repository_id) references gitlab_installation_repositories (id)
);

create table gitlab_installations_map (
       installation_id bigint primary key,
       core_id uuid not null default (gen_random_uuid()),
       foreign key (installation_id) references gitlab_installations (id)
);

create table gitlab_pull_requests_map (
       repository_id bigint not null,
       pull_number bigint not null,
       core_id uuid not null default (gen_random_uuid()),
       primary key (repository_id, pull_number),
       foreign key (repository_id, pull_number) references gitlab_pull_requests (repository, pull_number)
);

create index gitlab_installations_map_core_id_idx
       on gitlab_installations_map using hash (core_id);

create index gitlab_repositories_map_core_id_idx
       on gitlab_repositories_map using hash (core_id);

create index gitlab_pull_requests_map_core_id_idx
       on gitlab_pull_requests_map using hash (core_id);

create view gitlab_change_dirspaces as
       select
        cd.base_sha as base_sha,
        cd.path as path,
        grm.repository_id as repository,
        cd.sha as sha,
        cd.workspace as workspace,
        cd.lock_policy as lock_policy
       from change_dirspaces as cd
       inner join gitlab_repositories_map as grm
             on cd.repo = grm.core_id;

create view gitlab_code_indexes as
       select
        ci.sha as sha,
        gim.installation_id as installation_id,
        ci.index as index,
        ci.created_at as created_at
       from code_indexes as ci
       inner join gitlab_installations_map as gim
             on ci.installation = gim.core_id;

create view gitlab_drift_schedules as
       select
        ds.reconcile as reconcile,
        grm.repository_id as repository,
        ds.schedule as schedule,
        ds.updated_at as updated_at,
        ds.tag_query as tag_query,
        ds.name as name,
        ds.window_start as window_start,
        ds.window_end as window_end
       from drift_schedules as ds
       inner join gitlab_repositories_map as grm
             on ds.repo = grm.core_id;

create view gitlab_drift_unlocks as
       select
        grm.repository_id as repository,
        du.unlocked_at as unlocked_at
       from drift_unlocks as du
       inner join gitlab_repositories_map as grm
             on du.repo = grm.core_id;

create view gitlab_gate_approvals as
       select
        ga.approver as approver,
        ga.created_at as created_at,
        gprm.pull_number as pull_number,
        gprm.repository_id as repository,
        ga.sha as sha,
        ga.token as token
       from gate_approvals as ga
       inner join gitlab_pull_requests_map as gprm
             on ga.pull_request = gprm.core_id;

create view gitlab_gates as
       select
        g.created_at created_at,
        g.dir as dir,
        g.gate as gate,
        gprm.pull_number as pull_number,
        gprm.repository_id as repository,
        g.sha as sha,
        g.token as token,
        g.workspace as workspace
       from gates as g
       inner join gitlab_pull_requests_map as gprm
             on g.pull_request = gprm.core_id;

create view gitlab_pull_request_unlocks as
       select
        gprm.pull_number as pull_number,
        gprm.repository_id as repository,
        pru.unlocked_at as unlocked_at
       from pull_request_unlocks as pru
       inner join gitlab_pull_requests_map as gprm
             on pru.pull_request = gprm.core_id;

create view gitlab_repo_configs as
       select
        gim.installation_id as installation_id,
        rc.sha as sha,
        rc.created_at as created_at,
        rc.data as data
       from repo_configs as rc
       inner join gitlab_installations_map as gim
             on rc.installation = gim.core_id;

create or replace view gitlab_repo_trees as
       select
        gim.installation_id as installation_id,
        rt.sha as sha,
        rt.created_at as created_at,
        rt.path as path,
        rt.changed as changed,
        rt.id as id
       from repo_trees as rt
       inner join gitlab_installations_map as gim
             on rt.installation = gim.core_id;

create view gitlab_work_manifests as
       select
         wm.base_sha as base_sha,
         wm.completed_at as completed_at,
         wm.created_at as created_at,
         wm.id as id,
         gprm.pull_number as pull_number,
         grm.repository_id as repository,
         wm.run_id as run_id,
         wm.run_type as run_type,
         wm.sha as sha,
         wm.state as state,
         wm.tag_query as tag_query,
         wm.username as username,
         wm.dirspaces as dirspaces,
         wm.run_kind as run_kind,
         wm.environment as environment,
         wm.runs_on,
         gir.installation_id as installation_id,
         gir.owner as repo_owner,
         gir.name as repo_name
       from work_manifests as wm
       inner join gitlab_repositories_map as grm
             on wm.repo = grm.core_id
       inner join gitlab_installation_repositories as gir
             on gir.id = grm.repository_id
       left join gitlab_pull_requests_map as gprm
            on wm.pull_request = gprm.core_id;

-- Trigger for updating installations map
create or replace function insert_gitlab_installations_map()
returns trigger as $$
begin
    insert into gitlab_installations_map (installation_id)
    values (new.id);
    return new;
end;
$$ language plpgsql;

create or replace trigger trigger_insert_gitlab_installations_map
after insert on gitlab_installations
for each row
execute function insert_gitlab_installations_map();

-- Trigger for updating repositories map
create or replace function insert_gitlab_repositories_map()
returns trigger as $$
begin
    insert into gitlab_repositories_map (repository_id)
    values (new.id);
    return new;
end;
$$ language plpgsql;

create or replace trigger trigger_insert_gitlab_repositories_map
after insert on gitlab_installation_repositories
for each row
execute function insert_gitlab_repositories_map();

-- Trigger for updating pull requests map
create or replace function insert_gitlab_pull_requests_map()
returns trigger as $$
begin
    insert into gitlab_pull_requests_map (repository_id, pull_number)
    values (new.repository, new.pull_number);
    return new;
end;
$$ language plpgsql;

create or replace trigger trigger_insert_gitlab_pull_requests_map
after insert on gitlab_pull_requests
for each row
execute function insert_gitlab_pull_requests_map();

-- Latest unlock views
create view gitlab_pull_request_latest_unlocks as
    select
        repository,
        pull_number,
        max(unlocked_at) as unlocked_at
    from gitlab_pull_request_unlocks
    group by repository, pull_number;

create view gitlab_drift_latest_unlocks as
    select
        repository,
        max(unlocked_at) as unlocked_at
    from gitlab_drift_unlocks
    group by repository;
