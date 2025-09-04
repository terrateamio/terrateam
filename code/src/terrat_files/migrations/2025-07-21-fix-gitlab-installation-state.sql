insert into gitlab_installation_states values('installed');

alter table gitlab_installations
    add foreign key (state) references gitlab_installation_states(id);


update gitlab_installations
    set state = 'installed'
    where state = 'active';

delete from gitlab_installation_states where id = 'active';
