create table if not exists flow_states (
       id uuid primary key,
       data text not null,
       updated_at timestamp with time zone not null
);

create index flow_states_updated_at_idx on flow_states (updated_at);
