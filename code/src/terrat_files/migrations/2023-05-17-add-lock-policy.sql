create table lock_policies (id text primary key);

insert into lock_policies (id) values ('strict'), ('apply'), ('merge');

alter table github_dirspaces add column lock_policy text not null default 'strict' references lock_policies (id);
