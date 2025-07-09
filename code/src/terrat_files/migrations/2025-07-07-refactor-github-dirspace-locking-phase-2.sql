--
-- Fix work manifest trigger to take drift into account
--
create or replace function trigger_update_github_dirspace_locks_wm()
returns trigger as $$
declare
    pr_mapping record;
    result_row record;
begin
    if NEW.pull_request is not null then
        select repository_id, pull_number
        into pr_mapping
        from github_pull_requests_map
        where core_id = NEW.pull_request;
        if FOUND then
            for result_row in
                select * from  update_github_pull_request_dirspace_locks(pr_mapping.repository_id, pr_mapping.pull_number)
            loop
                RAISE NOTICE 'DIRSPACE : LOCK_CHANGE : %', result_row;
            end loop;
            RAISE NOTICE 'DIRSPACE : LOCK_UPDATE : WM : pull_request=% : repository=% : pull_number=% : state=% : run_type=%', 
                NEW.pull_request, pr_mapping.repository_id, pr_mapping.pull_number, NEW.state, NEW.run_type;
        else
            RAISE WARNING 'DIRSPACE : NO_MAPPING_FOUND : pull_request=%', NEW.pull_request;
        end if;
    end if;
    return NEW;
end;
$$ language plpgsql;


--
-- Add all of the existing pull requests into a migration table that we'll use
-- to incrementally migrate the pull requests over to the new system.
--
create table if not exists github_dirspace_locking_migration (
    repository bigint,
    pull_number bigint,
    primary key (repository, pull_number)
);

insert into github_dirspace_locking_migration (repository, pull_number)
select repository_id, pull_number from github_pull_requests_map
on conflict (repository, pull_number) do nothing;
