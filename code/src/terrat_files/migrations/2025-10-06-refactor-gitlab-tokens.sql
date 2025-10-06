alter table gitlab_installations
add column access_token text,
add column access_token_updated_by uuid,
add column access_token_updated_at timestamp with time zone,
add constraint fk_access_token_updated_by 
    foreign key (access_token_updated_by) references users2(id);
