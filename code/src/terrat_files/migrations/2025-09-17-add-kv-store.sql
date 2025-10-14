create table kv_store (
    namespace text not null,
    key text not null,
    idx smallint not null default 0,
    data jsonb not null,
    committed boolean not null default true,
    created_at timestamp with time zone not null default (now()),
    data_size integer generated always as (char_length(data::text)) stored,
    version smallint not null default 0,
    primary key (namespace, key, idx)
);

-- Index for cleaning up uncommitted content
create index kv_store_created_at_ns_key_uncommitted_idx on
    kv_store (created_at, committed, namespace, key)
    where not committed;


create table users2_types(
    id text primary key
);

insert into users2_types(id) values
    ('user'),
    ('system'),
    ('api');


alter table users2
    add column type text not null default 'user',
    add foreign key (type) references users2_types(id);

-- Only allow one system users
create unique index users2_system_type_idx on users2(type)
    where type = 'system';


-- Create our system user
insert into users2 (type) values('system');
