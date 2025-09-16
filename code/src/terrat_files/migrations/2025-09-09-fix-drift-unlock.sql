create or replace function trigger_update_drift_unlock_abort_wm()
returns trigger as $$
declare
    repo_mapping record;
    result_row record;
begin
    for result_row in 
        update work_manifests
            set state = 'aborted', completed_at = now()
            where repo = NEW.repo and state in ('queued', 'running') and run_kind = 'drift'
            returning id
    loop
        RAISE NOTICE 'DRIFT : WM : ABORT : id=%', result_row.id;
    end loop;
    return NEW;
end;
$$ language plpgsql;

create trigger unlock_drift_trigger
    after insert on drift_unlocks
    for each ROW
    execute function trigger_update_drift_unlock_abort_wm();

