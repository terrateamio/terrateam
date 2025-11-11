alter table kv_store
    add column read_caps jsonb,
    add column write_caps jsonb;
