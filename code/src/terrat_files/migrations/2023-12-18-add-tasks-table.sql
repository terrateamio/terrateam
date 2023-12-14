create table if not exists task_states (
       id text primary key
);

insert into task_states values
       ('aborted'),
       ('pending'),
       ('running'),
       ('completed'),
       ('failed');

create table if not exists tasks (
       id uuid default gen_random_uuid() primary key,
       name text not null,
       state text not null default 'pending',
       updated_at timestamp with time zone not null default now(),
       foreign key (state) references task_states(id)
);
