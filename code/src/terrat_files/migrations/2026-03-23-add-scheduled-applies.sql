create table scheduled_applies (
    id uuid primary key default gen_random_uuid(),
    repo uuid not null,
    pull_number integer not null,
    tag_query text,
    scheduled_at timestamp with time zone not null,
    created_at timestamp with time zone not null default now(),
    created_by text not null,
    state text not null default 'pending',
    constraint scheduled_applies_state_check
        check (state in ('pending', 'running', 'completed', 'cancelled', 'expired'))
);

create index scheduled_applies_pending_idx
    on scheduled_applies (scheduled_at)
    where state = 'pending';
