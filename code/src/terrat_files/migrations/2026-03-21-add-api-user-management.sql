create table api_user_installations (
    api_user_id uuid not null references users2(id) on delete cascade,
    installation_id bigint not null,
    name text not null,
    created_by uuid not null references users2(id),
    created_at timestamp with time zone not null default (now()),
    primary key (api_user_id)
);

create index api_user_installations_installation_id_idx
    on api_user_installations(installation_id);
