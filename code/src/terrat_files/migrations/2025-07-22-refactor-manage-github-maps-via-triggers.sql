-- Trigger for updating installations map
create or replace function insert_github_installations_map()
returns trigger as $$
begin
    insert into github_installations_map (installation_id)
    values (new.id);
    return new;
end;
$$ language plpgsql;

create or replace trigger trigger_insert_github_installations_map
after insert on github_installations
for each row
execute function insert_github_installations_map();

-- Trigger for updating repositories map
create or replace function insert_github_repositories_map()
returns trigger as $$
begin
    insert into github_repositories_map (repository_id)
    values (new.id);
    return new;
end;
$$ language plpgsql;

create or replace trigger trigger_insert_github_repositories_map
after insert on github_installation_repositories
for each row
execute function insert_github_repositories_map();

-- Trigger for updating pull requests map
create or replace function insert_github_pull_requests_map()
returns trigger as $$
begin
    insert into github_pull_requests_map (repository_id, pull_number)
    values (new.repository, new.pull_number);
    return new;
end;
$$ language plpgsql;

create or replace trigger trigger_insert_github_pull_requests_map
after insert on github_pull_requests
for each row
execute function insert_github_pull_requests_map();
