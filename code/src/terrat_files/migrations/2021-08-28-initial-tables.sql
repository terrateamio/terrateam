create table if not exists github_installations (
       access_tokens_url varchar(1024) not null,
       active boolean default true not null,
       created_at timestamp with time zone not null,
       html_url varchar(1024) not null,
       id bigint primary key,
       login varchar(256) not null,
       login_url varchar(1024) not null,
       pub_key varchar(1024) not null,
       secret uuid not null,
       suspended_at timestamp with time zone,
       target_type varchar(20) not null,
       updated_at timestamp with time zone not null
);

create table if not exists github_installation_repositories (
       full_name varchar(256) not null,
       id bigint primary key,
       installation_id bigint not null,
       name varchar(256) not null,
       node_id varchar(256) unique,
       private boolean not null default false,
       url varchar(1024) not null,
       foreign key (installation_id) references github_installations (id)
);
