set transaction isolation level repeatable read;

insert into terraform_versions values
       ('0.8.8'),
       ('0.9.11'),
       ('0.10.8'),
       ('0.11.15'),
       ('0.12.31'),
       ('0.13.7'),
       ('0.14.11'),
       ('0.15.5'),
       ('1.0.5');

create table if not exists default_terraform_version (
       updated_at timestamp with time zone default now(),
       version varchar(64) primary key,
       foreign key (version) references terraform_versions
);

insert into default_terraform_version (version) values ('1.0.5');
