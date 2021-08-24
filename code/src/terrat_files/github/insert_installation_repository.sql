insert into github_installation_repositories (
       full_name,
       id,
       installation_id,
       name,
       node_id,
       private,
       url
)
values (
       $full_name,
       $id,
       $installation_id,
       $name,
       $node_id,
       $private,
       $url
)
on conflict do nothing
