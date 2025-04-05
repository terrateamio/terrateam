create table if not exists tiers (
    id text primary key,
    name text not null,
    features jsonb not null default '{}'
);


insert into tiers (id, name) values('unlimited', 'Unlimited');

alter table github_installations
    add column tier text not null default 'unlimited' references tiers (id);
