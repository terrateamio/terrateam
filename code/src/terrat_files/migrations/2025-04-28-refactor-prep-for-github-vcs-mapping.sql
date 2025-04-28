create table github_repositories_map (
       repository_id bigint primary key,
       core_id uuid not null default (gen_random_uuid()),
       foreign key (repository_id) references github_installation_repositories (id)
);

create table github_installations_map (
       installation_id bigint primary key,
       core_id uuid not null default (gen_random_uuid()),
       foreign key (installation_id) references github_installations (id)
);

create table github_pull_requests_map (
       repository_id bigint not null,
       pull_number bigint not null,
       core_id uuid not null default (gen_random_uuid()),
       primary key (repository_id, pull_number),
       foreign key (repository_id, pull_number) references github_pull_requests (repository, pull_number)
);

alter table change_dirspaces
      add column repo uuid;

alter table code_indexes
      add column installation uuid;

alter table drift_schedules
      add column repo uuid;

alter table drift_unlocks
      add column repo uuid;

alter table gate_approvals
      add column pull_request uuid;

alter table gates
      add column pull_request uuid;

alter table pull_request_unlocks
      add column pull_request uuid;

alter table repo_configs
      add column installation uuid;

alter table repo_trees
      add column installation uuid;

alter table work_manifests
      add column repo uuid,
      add column pull_request uuid;

create view github_change_dirspaces as
       select
        cd.base_sha as base_sha,
        cd.path as path,
        grm.repository_id as repository,
        cd.sha as sha,
        cd.workspace as workspace,
        cd.lock_policy as lock_policy
       from change_dirspaces as cd
       inner join github_repositories_map as grm
             on cd.repo = grm.core_id;

create view github_code_indexes as
       select
        ci.sha as sha,
        gim.installation_id as installation_id,
        ci.index as index,
        ci.created_at as created_at
       from code_indexes as ci
       inner join github_installations_map as gim
             on ci.installation = gim.core_id;

create view github_drift_schedules as
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
       inner join github_repositories_map as grm
             on ds.repo = grm.core_id;

create view github_drift_unlocks as
       select
        grm.repository_id as repository,
        du.unlocked_at as unlocked_at
       from drift_unlocks as du
       inner join github_repositories_map as grm
             on du.repo = grm.core_id;

create view github_gate_approvals as
       select
        ga.approver as approver,
        ga.created_at as created_at,
        gprm.pull_number as pull_number,
        gprm.repository_id as repository,
        ga.sha as sha,
        ga.token as token
       from gate_approvals as ga
       inner join github_pull_requests_map as gprm
             on ga.pull_request = gprm.core_id;

create view github_gates as
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
       inner join github_pull_requests_map as gprm
             on g.pull_request = gprm.core_id;

create view github_pull_request_unlocks as
       select
        gprm.pull_number as pull_number,
        gprm.repository_id as repository,
        pru.unlocked_at as unlocked_at
       from pull_request_unlocks as pru
       inner join github_pull_requests_map as gprm
             on pru.pull_request = gprm.core_id;

create view github_repo_configs as
       select
        gim.installation_id as installation_id,
        rc.sha as sha,
        rc.created_at as created_at,
        rc.data as data
       from repo_configs as rc
       inner join github_installations_map as gim
             on rc.installation = gim.core_id;

create view github_repo_trees as
       select
        gim.installation_id as installation_id,
        rt.sha as sha,
        rt.created_at as created_at,
        rt.path as path,
        rt.changed as changed
       from repo_trees as rt
       inner join github_installations_map as gim
             on rt.installation = gim.core_id;

create view github_work_manifests as
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
       inner join github_repositories_map as grm
             on wm.repo = grm.core_id
       inner join github_installation_repositories as gir
             on gir.id = grm.repository_id
       left join github_pull_requests_map as gprm
            on wm.pull_request = gprm.core_id;
