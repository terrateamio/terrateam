create table github_work_manifest_run_kinds (
    id text primary key
);

insert into github_work_manifest_run_kinds values ('drift'), ('pr'), ('index');

alter table github_work_manifests
    add column run_kind text,
    add foreign key (run_kind) references github_work_manifest_run_kinds(id);

update github_work_manifests as gwm1
    set run_kind = (case when gdwm.work_manifest is not null then 'drift'
                    else 'pr' end)
    from github_work_manifests as gwm
    left join github_drift_work_manifests as gdwm
        on gdwm.work_manifest = gwm.id
    where gwm.id = gwm1.id;

alter table github_work_manifests
   alter run_kind set not null;
