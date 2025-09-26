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
