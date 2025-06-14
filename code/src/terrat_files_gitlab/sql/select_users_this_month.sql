select distinct gwm.username, min(gwm.created_at) from gitlab_work_manifests as gwm
inner join gitlab_installation_repositories as gir
  on gwm.repository = gir.id
inner join gitlab_installations as gi
  on gir.installation_id = gi.id
where gwm.username is not null and gi.id = $installation_id
      and gwm.created_at >= date_trunc('month', current_date)
      and gwm.created_at < date_trunc('month', current_date + interval '1 month')
group by gwm.username
order by min(gwm.created_at)
