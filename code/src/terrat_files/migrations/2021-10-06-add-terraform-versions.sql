set transaction isolation level repeatable read;

create table if not exists terraform_versions (
       version varchar(64) primary key
);

alter table installation_config
      add constraint installation_config_default_terraform_version_fkey
          foreign key (default_terraform_version) references terraform_versions (version);
